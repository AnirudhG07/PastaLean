# TypeInfer engine — soundness & completeness audit

A survey of `TypeInfer/` (PyType lattice, Rules `typeOfExpr`, Solve/{Env,Usage,Fixpoint,Stamp,Interproc,SSA})
for places the engine can **assert a wrong type (unsound)**, **give up when it could infer (incomplete)**,
or produce **order-dependent / non-confluent** results. Grounded in the current code.

Legend: 🔴 unsound (can compile wrong code or mis-ascribe → compile error) · 🟡 incomplete (loses precision,
boxes to PyAny) · 🔵 confluence/robustness.

## A. Soundness — asserts a type that need not hold

- 🔴 **`x ** k` → int (`arith`/BinOp).** `Rules.arith` types `int**int` as `int`, but Python `2 ** -1 = 0.5`
  (float), and `2 ** k` for a variable `k` is float when `k<0`. Verified: emits `(2:Int) ^ₚ (-(1:Int))`.
  Sound only for known-non-negative exponents. Fix: `**` with a possibly-negative int exponent → float
  (or leave `unknown`); a literal non-negative exponent stays int.
- 🔴 **`x + 1` / `x * 2` on a plain name ⇒ that numeric literal's type** (`Usage.numLit`). `x + 1` types
  `x : int`, but `x` may be `float` (`1.5 + 1`). Pragmatic (dominant case) but not *always* correct —
  a `list[float]` written `[x+1 for x in xs]` would mis-type `int`. Now excludes `pow` (good). Consider
  widening to "numeric" rather than committing to `int`, or gating on no competing float evidence.
- 🟢 **Anchored ordered comparison** (`Usage`, `x < t` where `t`'s type is KNOWN). NOT unsound — this is
  a **sound specialization**. In the translated code `x < (1 : Int)` uses Lean's HOMOGENEOUS `<`, so
  Lean's own constant inference FORCES `x : Int`; the twin is well-typed and correct for `Int` inputs and
  never yields a wrong answer for the type it commits to. The only cost is **completeness**: Python's
  `x < 1` also permits `float`, so a genuinely polymorphic (int+float) function gets a twin specialized to
  one type — a loss of generality that **fails loudly** (a `List ℤ`-vs-float *compile* mismatch), never a
  silent wrong result. The truly unsound version was the OLD *unanchored* `word < ans → int` (neither
  operand typed → a pure guess that mis-typed two `str`s as `int`, wrong for the intended inputs); the
  anchor removed exactly that. (`x + 1 → int` / `x * 2 → int` are the same kind of specialization, though
  `+ₚ` is heterogeneous so the `int` there is a TypeInfer *choice* rather than Lean-forced.)
- 🔴 **`p[i] <op> <literal>` / `p[i].method()` ⇒ `p : list[…]`** (`Usage`). Assumes the subscripted
  container is a LIST. But `p` could be a **dict** (`d[k] < 5` ⇒ wrongly `p:list[int]`, not `dict[_,int]`),
  or `p` a str indexed to a char. Mitigated because a competing dict/`.keys()` signal joins to `any`, and
  str-literals are excluded — but a dict with no other signal is mis-typed. Consider requiring a positive
  list signal, or leaving `unknown` when a dict read of the same name exists.
- 🔴 **`map(f, xs)` ⇒ `list[f's return]` only reads a NAMED `f`** (`Rules.builtinReturn`, added this
  session). Sound for `int`/`str`/user-fn. For a lambda callback it's `list[unknown]` (fine, not unsound),
  but for a builtin like `map(abs, xs)` → `abs` isn't in `constReturnBuiltins` as a *callback* return, so
  `list[unknown]` (incomplete, not unsound).

## B. Incompleteness — could infer soundly but doesn't (→ PyAny / unknown)

- 🟡 **List RETURN mixing is not reconciled** (the `_ret_float` scalar mechanism has no list analogue).
  `Stamp` detects `sawFloat`/`sawOther` only at TOP-LEVEL `.int`/`.float`; a body returning `list[int]`
  in one branch and `list[float]` in another has `returnTypeOf = list[float]` (correct!) but the do-block
  codomain is pinned by the FIRST `return [1]` (List Int) → mismatch. **This is exactly why Tri fails.**
  Fix: ascribe the do-codomain to the joined return type for containers too, and emit numeric list
  literals in return position unascribed so they coerce.
- 🟡 **`str * n` / `n * str` (string repeat) and `s % args` (%-format) → unknown** (`Rules`: `mul` only
  checks `.list` for repeat; `arith`/other ops don't handle str). Should be `str`.
- 🟡 **Backward dataflow through a local is not followed.** `arr → sorted_list = sorted(arr) → for x in
  sorted_list → to_word(x:int)` doesn't propagate `int` back to `arr` (ByLength, SortArray116,
  StrongestExtension). The callee-annotation rule only fires when the value is a DIRECT arg (`f(x)` /
  `f(arr[i])`), not when it flows through an intermediate binding. A backward/interprocedural pass would
  close these.
- 🟡 **`is_prime(a)` where the helper param is UNannotated.** The callee-annotation rule reads only
  ANNOTATED params. A nested helper whose param type is INFERRED (`a<2`⇒int) doesn't propagate back to
  the argument's source (Skjkasdkd, Intersection). Needs the helper's *inferred* signature.
- 🟡 **`return None` in a boxed-return function emits `Option.none`, not `PyAny.none`** (CompareOne,
  NextSmallest). A codegen gap, not inference — but it makes an otherwise-fine PyAny return fail.
- 🟡 **str-vs-list[str] is genuinely undecidable** without a hint (CountUpper/Encode/Solve161/HexKey/
  RemoveVowels). Correct to leave — noted so it's not mistaken for a bug. (See `bounded-dynamic-typing`.)
- 🟡 **`round`/`map` behaviours don't read a LAMBDA's body return** (only named callbacks / literal
  ndigits). `map(lambda x: x/2, xs)` → `list[unknown]`.

## C. Confluence / robustness

- 🔵 **`join` is now associative** for the `None`/`opt`/`any` cases (absorption `Optional[Any]→Any` was
  added). Good. Container/tuple/fn cases recurse structurally — associative. `a.beq b else any` fallback
  is fine. No known non-confluence remaining, but there is **no proof/test** that `join` is associative
  over the full lattice (only spot cases). A `#guard`/`native_decide` associativity check over a small
  model would harden the "verified lattice" claim.
- 🔵 **Usage vs fixpoint can disagree.** `usageType` (structural, per-name) and `applyStmt`/`inferFunction`
  (env fixpoint) can reach different conclusions; the merge order (`paramUsageSeed` then annotations then
  hints, with `refineElem`) is subtle and only partially tested. The `refineElem` "keep concrete usage
  element over a bare `.any` annotation" is load-bearing and easy to regress.
- 🔵 **SSA loop-carried type mutation is not modelled** (v1). A variable whose type changes *across loop
  iterations* keeps its pre-loop version — could be unsound if such a case arises (rare). Documented.
- 🔵 **`_ret_ty` from globals-free `sigs` can disagree with the env-seeded body** — the `sawAny`
  authoritative-boxing patch handles the known case, but the two sources of the return type (`sigs` vs
  env) are a recurring hazard.

## D. The specific question: are RETURN types concrete, not PyAny?

Mostly yes now:
- Single-type returns → concrete (`_ret_ty`). SSA makes a type-changing return concrete (CountNums → int).
- **Boxed only when returns genuinely disagree** (`.any`) or a branch yields PyAny (`sawAny`) — correct.
- **Two real gaps:** (1) list return-mixing (Tri — `list[int]`⊔`list[float]` not ascribed onto the
  codomain), (2) `return None` in a boxed function (Option.none vs PyAny.none). Both are the return-side
  analogues of param issues and are the clearest next fixes.

## Priority fixes (sound + tractable)
1. **List return-mixing** (Tri): ascribe the do-codomain to the joined container return type; emit numeric
   list literals unascribed in return position. (Return-type correctness — user's ask.)
2. **`return None` → `PyAny.none`** in a `_box_return` function (CompareOne, NextSmallest).
3. **`str * n` / `s % args` → str** (`Rules`), and **`x ** negative` → float** (soundness).
4. **Backward/inferred-helper propagation** (ByLength, Skjkasdkd cluster) — larger, interprocedural.
