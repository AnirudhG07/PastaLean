# Questions

Some general questions i have:
- How is `==` and `is` modelled? `is` should be value + type match, while `==` should be value match like `1==1.0` is True but `1 is 1.0` is False.

- can we make a PastaLean REPL? which get `term` wise converted and evaluated? (like a python REPL but with PastaLean + Python) both.

- How does python closures work in pastalean?
```
functions = []
for i in range(3):
    functions.append(lambda: i)

print([f() for f in functions])  
``` 

Here’s what you get:
```
Output >>> [2, 2, 2]
```

- the asterick operation is supported, but is it to this extent? 
a, *b = 1, 2, 3, 4
print(a, b)  
 

Output >>> 1 [2, 3, 4]
 

But this might surprise you:

a, *b, = 1,
print(a, b)  
 

Output >>> 1 []
 

And this is valid too:

(*a,) = [1, 2, 3]
print(a) 
 

Output >>> [1, 2, 3]

- Why is PyAny not containing all possible PyType and only a few mentioned? PyType contains everything that is possible, so why does PyAny not saying that? even `typing` library ones should technically be allowed in PyAny, right?

- shared mutable

def _add_item(item, bucket=[]):
    bucket.append(item)
    return bucket

def add_item():
    print(_add_item("a"))
    print(_add_item("b"))
    print(_add_item("c"))
    assert _add_item("d") == ["a", "b", "c", "d"]

---

## TypeInfer engine — soundness & gaps (survey 2026-08, to fix)

Architecture is sound: monotone fixpoint over a lattice (`join` = proper semilattice, `unknown`=bottom,
`any`=top; numeric tower `bool<:int<:float` widens correctly; Optional/None handled; conflicts→`any`).
`Lattice.lean` proves the core. Terminates. The issues below are coverage/soundness gaps, prioritized.

### P0 — `Lambda` is never typed (biggest win)
`typeOfExpr` has NO `Lambda` case → a lambda is `unknown`, so `.fn args→ret` is never inferred. That
means `sorted(xs, key=lambda x: …)`, `map`/`filter`/`min(…, key=…)` all lose the callback's type and
the element/result can't be recovered. This is why **SortArray116-class** (sort-by-key) problems stay
boxed. Fix: type `Lambda` as `.fn (param types) (body type)` and thread the callback through the
sort/higher-order Behaviours so the key's return type flows back to the element.

### P1 — no element inference from a `for`-loop variable
`usageType`'s `For` rule only fires for `ord(c)`→str. `for v in p: total += v` should teach
`p : list[int]` (v is an element, used as int) but doesn't. This is the iteration analogue of the
`p[i]`-arithmetic element rules just added. Add: `for v in p:` binds `v` to `p`'s element, then infer
`p`'s element from how `v` is used in the loop body.

### Soundness notes (heuristic — document as a deliberate assumption)
- **`p == []` ⇒ `list` is not strictly sound**: Python allows `5 == []` (returns `False`). ALL
  usage-back-inference (the new comparison rule AND the pre-existing `ord(p)`→str) assumes the program
  is **type-correct** — the gradual-typing / Shed-Skin stance. Fine in practice, but it can type a
  genuinely-polymorphic param. State this assumption explicitly in `TypeInfer/README.md`.
- **`(p[i] + p[j]) % 2` ⇒ `int` element is over-eager** — float `% 2` is legal Python. Rare; accepted.
- **`a ** b` ⇒ `int` (via `arith`)** when the result can be float (`2 ** -1 == 0.5`). Minor; the
  `PyHPow` instances catch it at compile time.

### P2 — small coverage gaps
- f-strings (`JoinedStr`) → `unknown`; should be `str`.
- bitwise `& | ^` on **sets** → `unknown` (`arith` only widens numerics; set ops not typed).

### P3 — fixpoint is a fixed 8-pass cap, not loop-until-stable
`Solve.lean:590` runs `for _ in [0:8]`. SOUND (climbs the lattice, never wrong) but potentially
INCOMPLETE for a deep `a→b→c→…` propagation chain needing >8 passes — could stop one type short of
settling. Make it loop-until-no-change (with a large safety cap) to remove the completeness risk for free.


---

## HumanEval compile-fail sweep (2026-08, after namespace + PyAny + Contracts fixes)

Fresh `regen` + `lake build …Generated` gives **~86/164 OK**. Fixes landed this pass:
- **Name-clash namespace**: user defs named `compare`/`unique`/`gcd`/`max` wrapped in
  `namespace PastaLean.User.Root` (driver assembles it, pastabench substitutes per-module). Removed
  the old broken `_root_`-qualification from Basic.lean + CallExpr.lean.
- **`DecidableEq PyAny`**: mutual `PyAny.decEq`/`decEqList` — lets `s = PyAny.str ""` resolve.
- **PyAny container protocols**: added `PyIntCast`/`PyContains`/`PyCount`/`PySlice`/`PySort`/`PySummand`
  on a boxed value (delegate-by-tag). NOTE the `outParam` trap: `PyContains`/`PyIterable` have
  `outParam β`, so only ONE instance per container type — per-needle variants break resolution; a
  concrete needle coerces via `CoeTail Int PyAny` instead.
- **Track-P accepts `if/elif: return`** (Contracts.lean `contractShape?`): a pure classification helper
  with an injected `Ensures` was falling to the monadic `Id` path → `helper x : Id String` → a caller
  using it purely became `List (Id String)` (`BEq (Id String)` failures). Now an `If` that
  `statementDefinitelyReturns` stays pure (when `referenceFn`). Fixed NumericalLetterGrade.

### Remaining dominant buckets (78 fail)
1. **Contract-spec comprehensions over `PyAny` params** (biggest). `all(x > 0 for x in lst)` in an
   injected `Requires`/`Ensures` lowers to `decide (x > (0:Int))` — the native `>` + Int literal forces
   the element to `ℤ`, but the param `lst` stayed `PyAny` → `PyIterable PyAny ℤ` (β is `outParam`, so no
   instance). Root: TypeInfer leaves the param `PyAny` while its spec-comprehension var is concrete.
   Fix is TypeInfer consistency (if a param is `PyAny`, its iteration/element vars in specs must be
   `PyAny` too, using boxed comparisons) — OR back-infer the param to `list[int]` from the spec usage.
2. **Genuinely-polymorphic params** (`def unique(l): return sorted(set(l))`, StrongestExtension's
   `class_name`/`extensions`) — no element-pinning usage → `PyAny` → metavariable-stuck. Needs a
   default element type or the `PyAny` protocol surface to be complete enough to elaborate.
3. **`type(x)` / `isinstance(x, T)`** (AnyInt, CheckDictCase) — type introspection emitted as bare
   `type`/`int`/`isinstance` identifiers. Needs a codegen feature: lower `type(x) == int` /
   `isinstance(x, int)` to a `PyAny` tag predicate (requires `x : PyAny`).
4. **`PyIterable (List ℤ) String`** — TypeInfer typed a loop var `String` over a `List ℤ` container
   (inconsistent); unsound to paper over with an instance — fix in TypeInfer.

---

## LeetCode convert fixes (2026-08, this batch)

Root-caused and fixed from a fresh `convert` (the overnight log was stale — pre-dated the PyAny work):

1. **Trie/recursive-class "Type mismatch: Trie.new has type Trie but expected PyAny" (~10 files).**
   Root cause in TypeInfer `applyMutation`: a user method whose name collides with a container method
   (`node.insert(...)` vs `list.insert`) was read as the LIST behaviour, re-teaching the receiver as a
   list → joined with `.cls Trie` → `PyAny`, cascading to every `node.children` access. Fix: skip
   library method behaviours when the receiver types as `.cls _`/`.opt (.cls _)`. Recovered every Trie
   file (add-bold-tag, replace-words, longest-word-in-dictionary, maximum-xor-*, bold-words-in-string, …).

2. **`chain(*g)` / `product(*t)` star-unpack** (zigzag, and chain users). A single `*iterable` spread
   means the ONE arg already IS the list of iterables, so `pyChain g` / `pyProduct t` — the old code
   wrapped it (`pyChain [g]`), nesting one level too deep (`PyStringJoin (List String)` etc.). Fixed in
   `SpecialCalls/Itertools.lean`. (product-of-tuples with unpack is still a deeper, separate issue.)

### Still open (leetcode)
- **Boxed index on a typed container** (`s[i]`/`xs[i]` with `i : PyAny`) — `PyGetItem`'s `ι` is an
  `outParam`, so a per-index-type instance (`PyGetItem String PyAny`, `PyGetItem (List α) PyAny`) is
  DEAD (Lean picks the `Int` instance first and never tries it). Needs a codegen unbox (`pyInt i`) or
  a TypeInfer fix that types the index — NOT a runtime instance.
- `type(x)`/`isinstance` introspection; `for i,(_,*e) in enumerate(...)` nested+star for-unpack.

### Overnight eval "all tests fail" (0/211463) — NOT a code regression
The evaluate phase compiles all 2184 harnesses into native binaries in ONE build; the disk was at
**99% (5.1 GB free)** and the run printed the low-disk warning. The native build exhausted the disk
("20 linked, 2164 compile_fail"), so every problem reported compile_fail. Convert itself is ~90% ok.
Free disk before the next full eval.
