# LeetCode corpus — failure taxonomy & fix plan

A robust, prioritized to-do for pushing the `dataset_leetcode` pass rate up. Built from
`overnight_leetcode.log` + `convert_summary.json` (the overnight run, ~1979/2589 problems before it
died on `No space left on device`) and live re-checks.

> **Caveat — the numbers below are STALE.** `convert_summary.json` predates this session's fixes
> (numeric-container read+write, for-target/np.shape list-unpack, mixed int/float return codomain,
> value+rest tuple-unpack/return/aug-assign, heapreplace). Treat the *categories* as the map; re-run
> `convert` after a fix to get true counts. A fresh run needs disk headroom + ~hours.

## Outcome snapshot (overnight run, 1008 evaluated + 1233 convert/compile-fail)

| bucket | count | meaning |
|---|---|---|
| lean N/N pass | 810 | correct |
| **lean 0/N** | 156 | compiles, **all** outputs wrong |
| **partial (0<lean<N)** | 42 | compiles, **some** outputs wrong ("half-running") |
| `[timeout]` | 121 | eval infra (heartbeat / per-case budget) |
| `[backend boot failed]` | 10 | Mathlib boot timeout |
| `[compile_fail]` | 896 | emitted Lean, didn't elaborate |
| `[convert_fail]` | 337 | codegen threw, no Lean emitted |
| ref incomplete (python<total) | 5 | dataset's own reference under-ran |

## Verdict on "half-running" — it is WRONG ANSWERS, not eval limits

The harness builds ONE `main` that folds over a runtime `List` of cases and prints `PASSED p/t`
(`build_test_harness`, cpasta_eval.py:359). A `p/t` line with full `t` proves `main` ran to the end —
so partial/zero results are `lean_got != expected` value mismatches, recorded in
`<prob>/eval/sol_0.json → failures`. `eval_divergences.json` was empty only because the run crashed
before writing it. Confirmed:
- `clear-digits("a1b2c3d4e5")` → exp `""`, got `"abcde"` — the stack `.pop()` that deletes the char
  left of each digit is mis-lowered.
- `convert_to_hex(-1)` → exp `"ffffffff"`, got `""` — negative / two's-complement path returns empty.

So the 156 + 42 are **correctness bugs** (§4), not eval timeouts. The 121 `[timeout]` ARE infra (§5).

---

## §1 · CONVERT_FAIL — codegen can't emit (337; ~fixable, high leverage)

Ranked by frequency. Several are PARTLY DONE this session — verify before redoing.

1. **[PARTLY DONE] value+rest mutating calls** — `heapq.heappop` (50), `deque.popleft` (35),
   `list.pop` return+mutate (29), `heapreplace` (4). DONE: single-`Name` assign, tuple-unpack,
   `return`, aug-assign, + `heapreplace` registration. **REMAINING: sub-expression positions** —
   `mx = -heappop(pq)`, `i = heappop(q)[1]`, `f(heappop(h))`. Fix = a statement-level *hoist*:
   `let __v := valFn recv; recv := restFn recv` before the stmt, substitute `__v` for the call node.
   GUARD (correctness): single such call, in an always-evaluated position (not under `IfExp`/`BoolOp`),
   receiver not read elsewhere in the expr (else `len(h)+heappop(h)` is silently wrong). See
   `mutatingCallRhsLowering?` (CallShared.lean), `[[value-rest-mutating-calls]]`.

2. **nested function as value** (42) + **mutual recursion** (29) + **generator-rebind** (19) —
   `sort(key=dfs)`, `dfs`↔`check` siblings, `dfs` inside a `GeneratorExp` that rebinds state.
   **[nested-as-value: DONE for capture-free helpers]** — `sort(key=score)` now lifts `score` to the
   top-level `_solve_score` and references it (`ClosureConvert.lean` rewriteHelperCalls value path +
   the early `usedAsValue` gate now keyed on `!captures.isEmpty`). A CAPTURING helper used as a value
   is still rejected (captures are appended *after* its params, so `new cap` mis-applies — a correct
   version needs a `fun p ↦ new p caps` lambda wrapper). **REMAINING: mutual recursion** → emit a
   `mutual … end` block; **generator-rebind** → thread the accumulator explicitly. See
   `[[closure-conversion]]` `[[lean-ir-transforms]]`.

3. **string methods** (~20) — `rstrip`/`lstrip`/`strip(chars)`, `zfill`, `rfind`, `ljust`/`rjust`,
   `title`, `find(sub, start)`. Each = one runtime fn in `PyAPI/Strings.lean` + a `pythonMethodMap`
   entry in `Attributes.lean`. Pure library work, no codegen change.

4. **Subscript assignment through an attribute** (21) — `self.grid[i][j] = v` (beyond depth-1),
   `obj.arr[i] = v` (non-`self` receiver). `Assign.lean` only supports `self.x[i]=v` via the `self`
   shadow. Fix: for `obj.attr[i] = v`, rebuild `obj.attr` with `pySetItem` and record-update `obj`.

5. **tuple-assignment targets** (13) — `a[i], b[j] = x, y` (subscript targets), nested tuple targets
   `a, (b, c) = …`. Extend `tupleAssignTargetNames?` / the doElem unpack to allow subscript + nested
   `Tuple` elements (recurse). `[[leetcode-bug-batch]]` (swap `a[i],a[j]=a[j],a[i]` was fixed; general
   case remains).

6. **keyword arguments** (12) — `max(…, default=0)`, `sorted(…, reverse=True)`, `dict.get(k, d)`,
   `int(s, base)`. Add a per-builtin kwarg allowlist that maps `key=val` to positional/optParam.

7. **itertools / collections gaps** — `itertools.count`/`chain` (5), `collections.deque` as a value
   (3), `functools.cmp_to_key` (1). deque already has `popleft`; wire `deque(...)` construction +
   `.append`/`.appendleft` as list ops. `count`/`chain` = lazy — bound them or degrade.

8. **misc** — `zip()` single arg (8) → `enumerate`-like or identity-zip; **walrus in BoolOp** (5)
   (`if (n := f()) and n > 0`) — evaluated conditionally, needs short-circuit-aware hoist;
   `defaultdict(Counter)` / `defaultdict(set)` (4); `max()` no-arg-default; `Counter.most_common` (6);
   `bisect_left/right` as *methods* (9) vs the working `bisect.*` free functions.

## §2 · COMPILE_FAIL — emitted Lean, didn't elaborate (896)

The stored errors truncate the instance goal, so "other" (394) is mostly `failed to synthesize` whose
class name lives on the next (dropped) line. From live analysis (`[[compile-fail-typeclass-taxonomy]]`):

1. **[DONE] numeric container `List ℚ` vs `Int`** (read + write) — lattice numeric tower, comprehension
   inference, module-global seeding, slice typing, container ascription, `_inferred` marker.
2. **[DONE] tuple-unpack-on-list** (`Prod.snd` on `List ℤ`), **for-target list-unpack**, **mixed
   int/float return codomain** (`ans = inf` + `return <int>`), **negative index typed ℚ**.
3. **tuple indexed/iterated as list** (`PyGetItem (ℤ×ℤ) ℤ`, `PyIterable (ℤ×ℤ×ℤ×ℤ×ℤ)`) — a fixed
   `Prod` indexed/iterated by a *variable* (const `0`/`1` already → `Prod.fst/snd`). Fix: `Prod`
   instances for homogeneous tuples, OR convert a homogeneous tuple literal to a `List`. **NOW the top
   remaining synth bucket.**
4. **tuple nesting** (`A×B×C×D` right-nested vs `((A×B)×C)×D` left-nested) — a Prod-associativity
   inconsistency between construction and an inferred param type (24-game). Pick one nesting and use it
   in both `buildTuple` and the tuple `PyType → Lean` emitter.
5. **`x cannot be mutated`** (34) — a var reassigned but not detected as needing `let mut` (e.g.
   assigned only inside a branch, or via an aug-op on a fresh name). Widen the mutated-name analysis
   (`jsonMutatesName` / the `let mut` prelude) to catch conditional / first-in-branch assignment.
6. **`invalid reassignment, value has type …`** (19) — a variable rebound to an incompatible type that
   should box to `PyAny` but didn't (inference missed the conflict). Tighten the per-slot join in
   `TypeInfer/Solve.lean` so a genuine type conflict stamps `PyAny`.
7. **Option field access** — `.val` (21), `.next` (5), `.right` (2) on `Option TreeNode`/`ListNode`.
   `_unwrap_opt` handles `root.val`; extend to chained (`root.left.val`) and to `ListNode.next`.
8. **`Unknown identifier next`** (8), **`SortedList`** (6), **`Function expected`** (7),
   **`Invalid match`** (12) — assorted; triage individually after the big buckets shrink.
9. **`PyContains PyAny`**, **`PyHAdd Bool Bool Bool`** (bool sum wants Bool not Int),
   **`PyGetItem (List defaultdict) …`** — small typeclass gaps.

## §3 · Already fixed this session (do NOT redo)

negative-index→Int; numeric-container read+write (lattice tower / comprehension inference /
global-seeding / slice typing / container ascription / `_inferred` marker); for-target & Assign
list-unpack (+`numpy.shape:list`); mixed int/float return codomain (gated `!_real_fn`, mix-only);
value+rest tuple-unpack/return/aug-assign + `heapreplace`; pure lowering for early-return; `pyany_cases`
in `taste?`. Committed: `0badbcf`, `db64ae7`, `9f41087`, and this session's uncommitted numeric work.

## §4 · RUNTIME WRONG ANSWERS — compiles, wrong output (156 all-wrong + 42 partial)

These are the "half-running" and "0/N" cases — **real correctness bugs**, the hardest to catch (no
compiler signal). Read `<prob>/eval/sol_0.json → failures` for `{args, expected, lean_got}`.

**Data-driven bucketing done** (script over every `eval/sol_*.json`): of 53 wrong-answer problems —
20 numeric, 13 len-diff, 9 string, 5 bool, 4 list-value, 1 reorder. Root causes fixed this session:

- **[DONE] `float('inf')` sentinel** (10 of 20 numeric) — `pyRatNonFinite` returned the stub `-1`, so
  the top-level shared `inf = float('inf')` (ℚ, used by both twins) made `-inf = 1`, breaking every
  `ans = -inf; max(ans, …)` / `best = inf; min(best, …)` initializer. Now a large ℚ sentinel `10^30`
  (+sign/nan). `maximize-the-beauty-of-the-garden` went 112/126 → **126/126**. Also fixes grid-game
  (`got=-1`), jump-game-vi, maximum-sum-circular-subarray, etc.
- **[DONE] `str.format` specs + `str.zfill`** — `pyStrFormat` only split on bare `{}`; now a real
  placeholder parser (`{}`/`{n}`/`{:spec}`, fill/align/zero-pad/width, `{{`/`}}`). `binary-watch`
  (`'{:d}:{:02d}'.format(...)`) now renders `0:01…8:00`. Added `pyStringZfill` (+`zfill` method map).

**REMAINING (needs infra, deferred):** the **set-comparison cluster** (keyboard-row `s <= s1` subset,
determine-if-two-strings-are-close `set==set`, intersection/find-the-difference ordering). Sets are
`List α`-backed, so `set <= set` lowers to List `≤` (lexicographic, NOT subset) and `set == set` to
List `BEq` (ordered, NOT order-independent) — both wrong. Fixing needs the Compare codegen to know an
operand is a set, but TypeInfer stamps `_ty` only on *binders*, not on Compare-operand `Name` nodes.
So: extend TypeInfer to stamp expression types (or thread a scope type-map into codegen), add runtime
`pySetEq`/`pySetSubset`, dispatch in `compareApplyTerm`. Set *iteration order* (CPython-exact) is
separately hard — defer.

Suspected common culprits (verify by sampling `failures`):
1. **[DONE] `list.pop()` / stack semantics** — `clear-digits` returned `"abcde"` for exp `""`: a bare
   `stk.pop()` statement lowered to `let _ := pyPop stk` (value computed, discarded, receiver never
   rebuilt). Fixed by a **unified in-place-mutator statement handler** (`statementMutatorRebuild?` in
   `CallExpr.lean`): one table + one branch replaces the old scattered `append`/`setMutatorName?`/
   `popleft`/`inPlaceMutatorArity?` branches, and now covers `pop`/`pop(i)`/`insert` too. Any mutating
   method used as a statement rebuilds its receiver (`stk := pyPopRest stk`), including subscript
   receivers (`g[i].pop()`). Verified: clear-digits `"a1b2c"→"c"`, pop/insert/reverse/extend/add.
2. **negative-number / bitwise** — `convert_to_hex(-1)` → `""`: two's-complement (`num & 0xffffffff`,
   `num += 1<<32`) mis-evaluates. Audit `pyBitAnd`/shift on negative `Int`, and `//`/`%` sign
   (Python floors toward −∞; Lean `Int.ediv`/`emod` vs `tdiv`/`tmod`).
3. **Float precision** — `ℚ` (prove twin) vs `Float` (`'rn`): the harness runs `'rn` (Float), so
   `0.1+0.2` etc. — expected decimal vs Float repr. Check the `repr`/`==` on Float outputs.
4. **ordering** — `set`/`dict` iteration order, `sorted` stability; a list-backed set may yield a
   different order than CPython's.
5. **string edge** — empty input, unicode, `split`/`join` on empty, `%` formatting.

Method: build a script that reads every `eval/*.json`, buckets `failures` by (return-type,
first-diverging-input-shape), and rank. That turns 200 opaque wrong-answers into ~5 root causes.

## §5 · EVAL INFRA — timeouts DOMINATE all missed cases (11.9k of 16.8k)

**Re-ranked by MISSED CASES, not problem count** (`total - passed` per eval json, all-N for errors):
of **16,767** missed cases across the corpus, **`[timeout]` = 11,916 (71%)**, boot = 1,017, the rest
(app-mismatch 467 / recursion 163 / type-mismatch 119 / died 103) small. Timeouts are THE lever.

**Diagnosed root cause (not just budget):** sequences are `List α`-backed, so `pyListAppend = lst ++
[elem]` is **O(n)** per append and `xs⦋i⦌` is O(i). A Python O(1) `for…: xs.append(v)` / index loop
becomes **O(n²)** in Lean. Compounded by the harness running `lean --run` (bytecode *interpreter*,
~50–100× slower than native). Together, array-heavy problems (two-pointer, prefix-sum, array DP) blow
the 15 s budget on large inputs — measured: a trivial append+index loop at n=3000 already runs seconds.

Fix paths (both substantial — scope with the user before committing):
1. **Array-backed sequences** — the real fix: back lists with `Array` (O(1) amortized append, O(1)
   index), removing the O(n²). Large runtime+codegen refactor (container type, all `CommonProtocols`
   instances, all list codegen). Biggest single lever; removes ~most timeouts regardless of interpreter.
2. **Native harness compile** — replace `lean --run` with a compiled binary. ~50–100× constant speedup,
   BUT Mathlib linking per-harness is heavy (why `--run` was chosen); only worth it if the Mathlib dep
   can be slimmed for eval harnesses. Helps O(n) / small-O(n²) cases; O(n²) still blows up at large n.
   Interim: raise the per-case wall-clock; detect+skip pathological inputs.
   See `[[cp-harness-oom-killed]]` `[[backend-heartbeat-poisoning]]`.
2. **`[backend boot failed: palc eval boot timed out]`** (10) — Mathlib boot > 10 s under load
   (these clustered near the disk-full crash). Raise the boot timeout; ensure disk headroom.
3. **whole-run `Killed` / disk-full** — the run died at 1979 on `No space left on device`; `.tmp`
   grows unbounded during eval. Cap/rotate `dataset_leetcode/.tmp`, and free disk before a full run.

## Suggested order of attack (leverage × safety)

1. **§1.2 closures/mutual recursion** (~90) — biggest convert_fail lever.
2. **§2.3 tuple-as-list instances** — top remaining compile synth bucket.
3. **§1.3 string methods** + **§1.6 kwargs** — cheap, additive, no codegen risk.
4. **§1.1 sub-expression hoist for value+rest** — finishes the heappop/pop cluster (needs the guards).
5. **§4 correctness audit** — script the `eval/*.json` bucketing FIRST, then fix the top 3 root causes
   (likely pop-semantics, negative-int bitwise, Float repr).
6. **§2.5/§2.6 mutation & reassignment analysis** — unblocks a long tail.
7. **§5 infra** — do before the next full overnight run (disk + timeouts).
