# LeetCode corpus — failure taxonomy & fix plan

Prioritized to-do for pushing `dataset_leetcode` pass rate up. Rebuilt 2026-07-25 from a **5-agent deep
diagnosis** of the latest overnight run (`overnight_leetcode.log`, HEAD `55f288d`) diffed against the
committed pre-batch baseline (`029703c`), plus 84 live re-converts on current `master`.

**Structure: CURRENT / IN-PROGRESS work is at the top, ranked by leverage. Already-DONE work is at the
bottom (§D).** Re-run `convert` after a fix for true counts — category counts here are de-duplicated to
*problems* (each file emits every def twice, `fn` + `fn'rn`, so raw error-occurrence counts double).

## Where we actually are (measured)

| stage | count | source |
|---|---|---|
| convert ok | 2038 | working-copy log (was 1779 at baseline `029703c` → **+259**) |
| convert compile_fail | 466 | (was 657 → −191) |
| convert convert_fail | 85 | (was 153 → −68) |
| native ok | 1915 | overnight `[*] compile finished … 1915 ok, 22 compile_fail` |
| native compile_fail | 22 | **harness type-inference bug, NOT codegen** — see §3.2 |
| convert-ok → native-scored gap | ~101 | problems with **0 runnable test cases** — see §3.3 |

**Session progress (2026-07-25, this batch — all verified, no regression; PALC not yet re-run):**
- ✅ **§0.1** for-target tuple-shadow — 6 regressions + §1.5 cluster (union-find etc.).
- ✅ **§3.2** harness float-poisoning — `cpasta_eval.py` now takes arg types from the twin signature
  AND decodes the expected value at the call's result type; `product-of-array-except-self` 0→39/39,
  sample 16/16 compile / 191/191 pass.
- ✅ **§1.1(a)** nested-helper subscript-index threading — `connecting-cities`, `satisfiability-of-
  equality-equations`, `gcd-sort-of-an-array` all 0 errors.
- ✅ **§1.1(b) void-return sliver** — recursive genuinely-void helpers now ascribe `: Unit`
  (`24-game` 8→0, `2-keys-keyboard` 2→0). The tree value-semantics-mutation + capture-completeness
  part of (b) is a larger feature, still open.
- ⏳ **§0.2/§1.3 (inf/numeric)** — diagnosed precisely (below) but NOT shipped: fix is TypeInfer-
  fixpoint-internal and this area is regression-prone; deeper debug is blocked by the persistent
  backend swallowing `dbg_trace`. Needs a backend-direct session + corpus validation.
- ⏳ **§3.1 (memoization)** — assessed: `@cache`/`@lru_cache` are currently *transparent*; real
  memoization needs an `@[implemented_by]` unsafe memo impl with redirected recursion + a global
  cache. Large additive feature, not started.

**Two headline reframes from the diagnosis:**
1. **The recent numeric/inf/List-ℚ batch is real but NARROW.** Re-converting 84 of the 466 compile_fails
   on current `master` (which contains every 07-25 fix) yields **0/84 fixed** (95%-CI true fixed-rate
   < ~3.6%). The batch fixed wrong-answers, convert_fails, and *container* `inf` — not the elaboration
   surface that dominates §1. Treat the 466 as **still-failing** and attack by root-cause cluster.
2. **A large share of "failures" are harness limitations, not transpiler bugs** — the 22 native
   compile_fails (float-poisoned test data, §3.2) and ~72–77 of the ~101 unscored problems
   (TreeNode/ListNode with no runnable case, §3.3) convert + compile fine.

---

# CURRENT / IN-PROGRESS (ranked by leverage × safety)

## §0 · REGRESSIONS to reverse FIRST (17 ok→compile_fail; pure recovery)

Baseline diff `029703c → 55f288d`, all 17 **re-confirmed failing on the current build**. Net corpus
movement is +259 ok, but these are real losses we introduced. Reversing them is the safest leverage.

1. **[✅ DONE — verified] for-loop TUPLE-target shadows a function-hoisted `let mut` (6 regressions,
   HIGH confidence) — commit `6b193e5`.** FIX: `forTargetBinder` Tuple case now mirrors the Name case —
   a target already a `let mut` in scope is assigned into (`x := Prod.snd _pair`), not shadowed. All 6
   regressed problems re-compile; also covers §1.5. Pattern: `x = arr[i]` … later `for i, x in enumerate(...)`.
   Function-scope hoisting lifts `x` to a `let mut x := default`; the later tuple for-target then emits
   `let x := Prod.snd _pair`, illegally shadowing the mutable → `mutable variable 'x' cannot be
   shadowed`. **Root cause pinpointed:** `forTargetBinder` in
   `PastaLean/PyGens/UseCases/ControlFlow.lean` — the **Name** case (~line 200) has a `hasVar` guard
   that *reassigns into* the existing mutable; the **Tuple** case (~lines 220-258) is **missing that
   guard**, so it re-binds and collides. Fix: give the Tuple case the same `hasVar`-aware path (assign
   `x := Prod.snd _pair` when `x` is already a mut, else bind). **This same fix also resolves §1.5
   (the broader 21-problem mutable-shadow cluster) — one edit, ~27 problems.** `beautiful-towers-ii`,
   `flower-planting-with-no-adjacent`, `get-biggest-three-rhombus-sums-in-a-grid`,
   `maximum-score-of-a-good-subarray`, +2.

2. **inf-seeded MUTABLE ACCUMULATOR boxes to `PyAny` (2 regressions) — commit `a1a37f5`. [DIAGNOSED, NOT FIXED]**
   `ans = inf` → `let mut ans : PyAny := inf`; `pyMin [ans, i-…]` then mixes `PyAny`+`Int`.
   **Precise diagnosis this session** (repros `infA`–`infH` in scratch): the box appears ONLY with
   `inf`-seed **AND** a `min`/`max` arg whose type reaches `int` only *after* a fixpoint iteration —
   i.e. a **dict-subscript** arg `min(ans, i - last[x] + 1)` (`last[x]` is transiently `unknown` until
   `last[x]=i` refines the dict value). Neither alone triggers it: `ans=999; min(ans, i-last[x]+1)` →
   `Int`; `ans=inf; min(ans, i-1)` → `Int`. Production numeric tower is correct (`join float int =
   float`, `PyType.lean:132`); the `let mut ans : PyAny` binder type comes from the **mutated-var
   hoist typing reading `env["ans"] == .any`**, NOT `stampTarget` (verified: `stampTarget` is never
   called for `ans`). So `.any` enters `inferFunction`'s intraprocedural fixpoint in the
   transiently-unknown-subscript case. **Deeper root-cause tracing is blocked**: the persistent
   backend swallows `dbg_trace` stderr — need a direct `lake exe py2lean` run to trace the fixpoint,
   then a corpus run to validate (this area is regression-prone per prior guidance). Fix direction
   unchanged: an `inf`-seeded mut var should adapt to the **join of its non-inf assignments**.
   `shortest-subarray-with-sum-at-least-k`, `minimum-consecutive-cards-to-pick-up`. See
   `[[numeric-mode-rat-default]]` `[[compile-fail-typeclass-taxonomy]]`.

3. **class equality lowers to propositional `=` needing `Decidable` (2 regressions).** `symmetric-tree`,
   `flip-equivalent-binary-trees`: the primary (non-`'rn`) def emits `if root1 = root2` on
   `Option TreeNode`, but generated `structure TreeNode` derives only `Inhabited, Repr, BEq` — no
   `DecidableEq` (`PastaLean/PyGens/UseCases/ClassDef.lean:305-320`). The `'rn` twin uses `==` (BEq) and
   is fine. Fix: add `DecidableEq` to the derive clause for generated classes (derivable — fields are
   `Option TreeNode`/`Int`), OR lower class `==` to `BEq` (`==`) in the pure path too. Ties into §1.4.

4. **other `PyAny` over-widening (7 regressions) — the TypeInfer/PyAny commits `e6ba2a6`, `f3b7c77`.**
   A var the baseline inferred as concrete `Int` is now `PyAny`, which lacks the operator/getitem
   instance. Sub-cases: generator lowering (`f3b7c77`) loses element type (`mi = min(<generator>)` →
   `PyAny`, `b-a = mi` mismatches Int); `t = Counter(a)` typed `Std.HashMap` but `pyCounter` returns
   `PyDefaultDict` → invalid reassignment; `PyDefaultDict PyAny (List ℤ)`; `PyGetItem (List ℤ) PyAny`;
   `PyHSub ℤ ℤ PyAny`. Fix: tighten TypeInfer seeding so `min/max` over a generator, `Counter(...)`, and
   defaultdict keys recover concrete element/key types instead of falling to `PyAny`.
   `minimum-absolute-difference`, `word-subsets`, `number-of-good-paths`, +4. See `[[typeinfer-engine]]`
   `[[pyvalue-fallback]]`.

## §1 · COMPILE_FAIL clusters (466; recent batch fixed 0/84 — this is the real surface)

Root-cause clusters overlap (a tree-DFS problem is in #1 and #4), so counts don't sum to 466. Ranked by
leverage × tractability.

1. **⭐ Nested recursive helper unresolved (52) — highest leverage. [(a),(b)-void ✅ DONE; tree-mutation part OPEN]**
   `Unknown identifier _fn'helper` / `_…'dfs` / `find`, cascading into "typeclass stuck", "match
   contains metavariables", App-mismatch. Two distinct bugs in
   `PastaLean/PyGens/Transform/ClosureConvert.lean`:
   - **✅ (a) un-renamed call in a subscript-assignment INDEX.** `p[find(x)] = find(y)`: the state-
     threading `Assign` branch built the combined `_thread_unpack` assign from the value call but read
     `target` as-is, so `find(x)` in the index stayed bare/unthreaded. FIX (`rewriteThreadedStmts`):
     hoist the target's threaded calls first (`hoistThreadedCalls` on `target`, prelude before the
     combined assign). `connecting-cities`, `satisfiability-of-equality-equations`, `gcd-sort-of-an-
     array` all compile now.
   - **✅ (b-void sliver) genuinely-void recursive helper** ascribed `: Unit` via new
     `recursiveReturnTypeSyntax?` in `FuncDef.lean` (guarded by `hasValuedReturn` on the BODY — the
     def-node guard short-circuits, which first mis-boxed `find` to `Unit`; fixed). `24-game`,
     `2-keys-keyboard` recovered.
   - **⏳ (b-tree) OPEN — the hard part:** a void DFS that mutates a captured/param structure
     (`root.left = …` in `add-one-row-to-tree`) needs **value-semantics tree-mutation threading**
     (the mutated tree returned + rebound), AND `add-one-row` shows a separate **capture-completeness
     bug** (`depth` passed at call sites but not declared as a param). Both are real features. Ties
     into `[[void-mutation-punit-bug]]` `[[closure-conversion]]`.

2. **bisect / heapq kwargs (30). [✅ kwarg-application bug FIXED; `key=` value-split still open]**
   The real blocker was NOT the shims — it was codegen applying a named arg to the *already-complete*
   `(f a b)` (`bisect_right(s, x, lo=…)` → `(pyBisectRight s x) (lo := …)`, "Invalid argument name"),
   because the shim's remaining params have defaults. FIXED: `buildApplied` (CallExpr.lean) now keeps
   the named args in the SAME application spine (`f a b (lo := …)`), handling 1–2 kwargs explicitly
   (`lo=`/`hi=`/`key=`/`reverse=`). `count-pairs-of-nodes` 0 errors; also fixes the `ListNode.new
   (next := …)` paren break (§4-node). REMAINING: `key=` as a value transform — `bisect_left(a, x,
   key=check)` / `nlargest(k, xs, key=)` splits needle/element types (`key(a[mid]) < x`); needs a
   `key`-aware shim overload. See `[[leetcode-library-imports]]`.

3. **Numeric inf / ℤ→ℝ/ℚ widening (33; 38 mention `inf`).** (a) scalar/tuple-bound `inf` mixed with int
   in `min`/`max` — `best-time-to-buy-and-sell-stock` (`ans, mi = (0, inf)`; `max(ans, v-mi)` →
   `v-ₚ mi : ℚ` expected `ℤ`); the container inf-fix doesn't reach scalar tuple binds. (b) mut var
   inferred `ℤ` at first assign, later reassigned wider (`ℝ` from `sqrt`) → `invalid reassignment` (21 of
   the 28 invalid-reassignments). (c) `dist[u] = 0` (ℤ) into `List ℚ` → `PySetItem (List ℚ) ℤ ℤ`. Fix:
   extend inf-adapt to scalar/tuple/mut binds (**merges with §0.2**); type a mut var as the **join of
   ALL its assignments**; widen SetItem values to the container element type. See
   `[[numeric-reconcile-tower]]`.

4. **Node/Option typing — linked-list + tree (49). [PARTIAL — 2 cluster problems recovered]** Fixed
   this session: (a) a param annotated as a bare `ListNode` but reassigned `curr = curr.next` — TypeInfer
   now stamps `_mut_opt`, codegen seeds the mut cursor as `Option c := some p` so truthiness + `.getD`
   field reads line up (`convert-binary…`, `remove-duplicates-from-sorted-list` now ✅); (b) **run-twin
   class params are now suffixed** (`head : ListNode'rn`, not the prove-twin `ListNode`) — a pre-existing
   gap `functionArgTypeSyntax?` masked, exposed once (a) coerced `some head`; (c) `ListNode.new (next := head)`
   ctor named-args emit on one application spine (2-kwarg `buildApplied` fix), no wrapping parens.
   Regression: `example_scripts/typing/optional_nodes.py::get_decimal`.
   **STILL FAILING (the hard core):** general `Option` field **read/write** in statement positions —
   `b = c = head.next` then `a.next = b.next` / `a = a.next` (`odd-even-linked-list`), node-returning
   builders (`add-two-numbers`), `PyTruthy`/`Ord (Option ListNode)` for node heaps (`middle-of-the-linked-list`).
   These need the P4 `reconcile`/`unwrapOpt` lifting (auto-unwrap on every `.field`, re-wrap on write),
   not just the cursor case. (§0.3 `DecidableEq` folds in here.)

5. **mutable var shadowed by for-target (21).** `beautiful-towers-ii`: `x` both a `let mut` and later a
   `for x in …` target. **SAME bug as §0.1** — fixing `forTargetBinder`'s Tuple/Name `hasVar` path
   resolves both.

6. **sort-key polymorphic lambda (16).** `sorted(items, key=lambda t: (-count, name))` emits
   `pySortBy (fun {α β} … ↦ (-Prod.snd x, …))` with fully-polymorphic implicit binders, so `-Prod.snd x`
   needs `Neg β` on unconstrained `β` → `failed to synthesize Neg β` / `ToString β`. Fix: ascribe the
   key-lambda's param type from the sorted collection's element type instead of generalizing.

7. **list/tuple-unpack confusion (~72; largest raw count). [✅ COMPREHENSION/GENERATOR case FIXED]**
   Iterating a list-of-lists and unpacking `for a, b in …` where the element is `List ℤ`, not `α × β`.
   **FIXED for comprehensions/generators**: `sum(a-b for a,b in transactions)` / `[(b,a) for a,b in
   edges]` (`transactions : list[list[int]]`) emitted `Prod.fst`/`Prod.snd` — a `for`-STATEMENT got the
   `_list_unpack` mark but a comprehension target didn't. Added `stampCompTargets` (TypeInfer, marks
   each comprehension generator's tuple target via `stampUnpackShape`) + `compAccessTerm` (ListComp
   codegen, `pyListGetItem` when marked). `minimum-money-required-…` 0 errors, runs correct (=10).
   REMAINING: `product(range,range)`/`zip` element-as-tuple inference (`campus-bikes`), and a
   heterogeneous tuple indexed by a literal — `cnt.most_common(1)[0][1]` → `PyGetItem (String × ℤ) ℤ`.
   Fix: infer the iterated-element type as a **tuple** when the
   unpack arity matches; statically project literal indices into tuples.

8. **SortedList / `sortedcontainers` (6) — genuinely unsupported, defer.** `from sortedcontainers import
   SortedList` → `Unknown identifier SortedList` (best-effort didn't degrade it). Needs a new library
   shim; largest effort, lowest count. See `[[best-effort-fallback]]`.

## §2 · CONVERT_FAIL — codegen can't emit (85; ~40% is one feature)

1. **⭐ nested-recursive / mutual-state-threading (~35, ~40% of convert_fails).** `dfs`↔`check` sibling
   mutual recursion, `dfs` inside a `GeneratorExp` that rebinds state, capturing helper used as a value.
   [nested-as-value DONE for capture-free helpers; **REMAINING**: mutual recursion → emit a `mutual …
   end` block; generator-rebind → thread the accumulator explicitly; capturing-helper-as-value → a
   `fun p ↦ new p caps` lambda wrapper (captures are appended after params, so `new cap` mis-applies).]
   See `[[closure-conversion]]` `[[value-rest-mutating-calls]]`.

2. **union false-positive (cheap).** A `set | set` / `dict | dict` union path mis-fires and throws where
   it shouldn't. Isolated, low-risk — cheap early win.

3. **value+rest mutating calls — sub-expression positions [PARTLY DONE].** DONE: single-`Name` assign,
   tuple-unpack, `return`, aug-assign, `heapreplace`. **REMAINING:** `mx = -heappop(pq)`,
   `i = heappop(q)[1]`, `f(heappop(h))` — a statement-level hoist (`let __v := valFn recv; recv :=
   restFn recv`), guarded to a single call in an always-evaluated position with the receiver not read
   elsewhere. See `mutatingCallRhsLowering?` (CallShared.lean), `[[value-rest-mutating-calls]]`.

4. **string methods (~20).** `rstrip`/`lstrip`/`strip(chars)`, `zfill` (done), `rfind`, `ljust`/`rjust`,
   `title`, `find(sub, start)` — one runtime fn in `PyAPI/Strings.lean` + a `pythonMethodMap` entry
   each. Pure library work.

5. **subscript-assignment through an attribute (21).** `self.grid[i][j] = v` (depth > 1),
   `obj.arr[i] = v` (non-`self` receiver). `Assign.lean` only supports `self.x[i]=v` via the `self`
   shadow. Fix: rebuild `obj.attr` with `pySetItem` and record-update `obj`.

6. **tuple-assignment targets (13).** `a[i], b[j] = x, y` (subscript targets), nested `a, (b, c) = …`.
   Extend `tupleAssignTargetNames?` / the doElem unpack to allow subscript + nested `Tuple` (recurse).

7. **misc.** `max(…, default=0)`/`sorted(…, reverse=True)`/`dict.get(k, d)`/`int(s, base)` kwargs;
   `itertools.count`/`chain` (lazy — bound or degrade); `functools.cmp_to_key`; walrus-in-BoolOp
   short-circuit hoist; `bisect_left/right` as *methods* vs the working free functions.

## §3 · EVAL / HARNESS — the biggest single lever is timeouts, and 2 harness bugs are free

### 3.1 · `@cache` / `@lru_cache` memoization — **61 timeout problems [✅ DONE, commit `c2cbfd7`]**
The runnable twin memoises so exponential `@cache` DP runs in polynomial time; the provable twin stays
the plain pure recursion. Went with a **pure `StateM`** worker (not `@[implemented_by]`+`initialize` —
that breaks under `lean --run`, which `pastalean run` uses): `partial def foo'memo'rn (params) : StateM
(HashMap Key Ret) Ret := do match (← get)[key]? with | some v => return v | none => let v ← (do
<body>); modify (·.insert key v); return v` + wrapper `foo'rn := (foo'memo'rn args).run' ∅`. Recursive
self-calls lower to `(← foo'memo'rn …)` via a codegen memoize-self context; `do`-notation hoists the
bind. Covers `int`/`bool`/`str` params (tuple key for multi-arg) and **nested `@cache dfs`** (keyed on
the ORIGINAL params — a lifted `_capture` is threaded through, not keyed). Falls back to the plain def
for a self-call in a ternary/`and`/`or`/lambda/comprehension or an untyped param. `fib(90)`/`countPaths`
verified vs CPython; 12/30 sampled corpus `@cache` memoise. See `[[unbounded-iterators]]`.

### 3.2 · ✅ DONE — 22 native compile_fails were **HARNESS float-poisoning, NOT codegen.** Namespaced
modules (`CpHarness.H<id>`), so not collisions. Root cause: `build_test_harness` derived the wrapper's
arg/expected Lean types from the concrete test DATA (`_lean_type_of`), independent of the twin.
**FIX (`cpasta_eval.py`), two parts:**
- **Arg types from the twin signature** — new `_signature_arg_types` parses the `'rn` twin's `fun (a :
  T) ↦ …` binder chain (`_normalize_lean_type` handles atoms/`List`/tuples, maps `ℤ/ℚ/ℝ`→`Int/Float`);
  overrides data inference per position. A stray `Float` in an Int column no longer flips the field —
  the runtime `fromJson?` decoder just drops the non-conforming case. (18/22.)
- **Expected value decoded at the CALL'S result type** — no longer data-typed; carried as raw `Json`
  and decoded per-case via `_decodeLike _got ejson` (unifies `α` with the twin's return), so tuple/
  int/float returns all resolve and only out-of-spec expected values drop. (Covers the 3/22 tuple-
  return and the expected-column float-poison, e.g. `product-of-array-except-self` 0→**39/39**.)
- **VERIFIED:** product-of-array-except-self compiles + 39/39; random sample 16/16 compile, 191/191
  pass; no regression. The 1/22 structural (`remove-duplicates-from-sorted-list`, `Option ListNode`
  input) still needs harness node-deserialization (§3.3). See `[[cpasta-eval-class]]`
  `[[native-eval-architecture]]`.

### 3.3 · ~101 convert-ok→never-scored = problems with **0 runnable test cases** (coverage ceiling).
The native selector drops any problem with 0 runnable cases (`if not cases: continue`): the dataset's
reference can't run on the parsed inputs (66 reference-fail + 36 method-not-found). By shape, **72–77 are
TreeNode/ListNode** — the harness parses `"[1,2,3]"` as a plain list but the Python reference wants a
`TreeNode`, so every case fails → 0 cases. These **convert + compile fine** but are silently never
scored. Recovering them needs list→node **deserialization** in the harness (a feature, not a bug).
`excluded_problems.txt` (2 active) is a fetch-time filter, irrelevant here.

### 3.4 · Array-backed sequences — O(n²) is the structural timeout cause (substantial; scope w/ user).
Sequences are `List α`-backed, so `pyListAppend = lst ++ [elem]` is O(n) and `xs⦋i⦌` is O(i): a Python
O(1) append/index loop becomes **O(n²)** in Lean. Backing lists with `Array` (O(1) amortized append/
index) is the real fix — large runtime+codegen refactor (all `CommonProtocols` instances + list
codegen), biggest single lever after memoization. See `[[cp-harness-oom-killed]]`
`[[backend-heartbeat-poisoning]]`.

## §4 · RUNTIME WRONG ANSWERS — compiles, wrong output (hardest; no compiler signal)

Read `<prob>/eval/sol_0.json → failures` for `{args, expected, lean_got}`.

1. **helper / method / nested-fn mutation persistence (~8-10 wrong-answers).** A mutation inside a
   helper/method/nested def doesn't persist to the caller (value semantics not threaded back). Overlaps
   §2.1. Root design work, high correctness value.
2. **[REMAINING] set-comparison cluster.** Sets are `List α`-backed, so `set <= set` lowers to List `≤`
   (lexicographic, NOT subset) and `set == set` to List `BEq` (ordered, NOT order-independent) — both
   wrong (`keyboard-row`, `determine-if-two-strings-are-close`). Fix needs Compare codegen to know an
   operand is a set, but TypeInfer stamps `_ty` only on binders, not Compare-operand `Name` nodes →
   extend TypeInfer to stamp expression types (or thread a scope type-map into codegen), add runtime
   `pySetEq`/`pySetSubset`, dispatch in `compareApplyTerm`. Set iteration order (CPython-exact) is
   separately hard — defer.
3. **negative-number / bitwise / floor-div sign.** Audit `pyBitAnd`/shift on negative `Int`, and `//`/`%`
   sign (Python floors toward −∞; Lean `Int.ediv`/`emod` vs `tdiv`/`tmod`).
4. **Float precision / repr** — the harness runs `'rn` (Float); check `repr`/`==` on Float outputs.
5. **ordering** — `set`/`dict` iteration order, `sorted` stability.

Method: script the `eval/*.json` bucketing (by return-type × first-diverging-input-shape) FIRST, then
fix the top root causes.

## Suggested order of attack (✅ = done this session)

1. ✅ **§0.1 for-target tuple-shadow** — `forTargetBinder` Tuple `hasVar` guard (~27 problems).
2. ✅ **§3.2 harness float-poisoning** — signature arg-types + decode-expected-at-result-type (~21).
3. ✅ **§1.1(a)+(b-void)** — subscript-index threading + void `: Unit` (union-find + 24-game/2-keys).
4. **§1.2 bisect/heapq `key=`** + **§2.2 union false-positive** — additive, low codegen risk (NOTE:
   `lo=`/`hi=` already work; only `key=` remains, and it's a real feature).
5. **§0.2+§1.3 inf-adapt to scalar/mut binds** + **§0.4 PyAny re-tightening** — reverses 9 regressions,
   unblocks §1.3 (33). **Blocked on backend-direct fixpoint tracing + corpus validation (see §0.2).**
6. **§1.1(b-tree) mutation threading** + **§2.1 mutual recursion / state-threading** + **§4.1 helper
   mutation persistence** — the remaining nested-helper feature; overlapping value-semantics design.
7. **§3.1 @cache/@lru_cache memoization** — 61 timeout problems, biggest eval lever (large additive).
8. **§1.4 Node/Option model** (start with the ListNode.new paren sub-win, 6) + **§0.3 DecidableEq**.
9. **§1.6 sort-key lambda**, **§1.7 tuple-unpack inference** — harder; after the above.
10. **§3.4 Array-backed sequences** — structural; scope with the user before committing.

---

# §D · DONE (do NOT redo)

## This session (2026-07-25 batch; PALC 90/0, committed)
- **List ℚ 2-D inf-DP ascription** (`aa94988`): `isListLitOrRepeat` recurses into ListComp/GeneratorExp/
  SetComp elts; `PySetItem (List ℚ) ℤ Float`/`ℤ` fixed for container literals.
- **mixed int/float ternary return reconcile** (`99a7117`, coin-change): `returnBranchTypes` descends
  IfExp/BoolOp, scoped to `IfExp` value nodes.
- **numeric widening tower** (bool < int < {float, ℚ} < ℝ; int < ℚ): bool `Coe` rungs, validated against
  "two ways to get ℚ" ambiguity.
- **Python float repr** (`8fef170`): `PyAPI/Builtins/FloatRepr.lean` — shortest round-trip repr matching
  CPython (`pi=3.141592653589793`, `1.0` not `1.000000`, `2/7=0.2857142857142857`).
- **inf-adapts** (`a1a37f5`): `float('inf')` typed `.unknown` so it adapts (coin-change prints `3`/`-1`/
  `0` as int; float DPs stay float). **NOTE: does NOT reach scalar/tuple/mut binds — see §0.2, §1.3.**
- **walrus-in-BoolOp first operand** (`3e181d3`): `hasWalrusUnder` special-cases the safe first operand.
- **str.splitlines** (`e2ab45a`); **defaultdict(deque)** + collections member map (`e2ab45a`).
- **any/all truthiness-context BoolOp** (`55f288d`): `truthinessContextRef` gives mixed `and`/`or` a
  Bool (not forced Prop); recovered `check-if-string-is-transformable-…`.
- **cherry-pick of 6 `ups` commits** onto master (`6b38589^..1870c09`); `types_and_assignments.py`
  verified.

## This session — UNCOMMITTED (PALC 90/0, awaiting explicit commit say-so)
- **§1.2 bisect/2-kwarg calls**: `buildApplied` emits ≤2 named args on ONE application spine
  (`f a (k := v) (k2 := v2)`), not nested-paren `((f) (k:=v)) (k2:=v2)` — needed for defaulted-param
  shims + `ListNode.new (next := head)`. Golden: `functions_and_calls.lean`.
- **§1.7 comprehension tuple-unpack**: `_list_unpack` stamp routes `for [a,b] in listOfLists` targets
  through `pyListGetItem` (not `Prod.fst/snd`); `stampCompTargets` in Solve.
- **§1.4 Node/Option (partial)**: `_mut_opt` inferred-nullable cursor + run-twin class-param suffix +
  ctor named-args. 2 cluster problems recovered (`convert-binary…`, `remove-duplicates…`). Regression:
  `optional_nodes.py::get_decimal`. Hard core (general Option field read/write) still open — see §1.4.

## Earlier sessions
negative-index→Int; numeric-container `List ℚ` read+write (lattice tower / comprehension inference /
global-seeding / slice typing / container ascription / `_inferred` marker); tuple-unpack-on-list
(`Prod.snd` on `List ℤ`); for-target & Assign list-unpack (+`numpy.shape:list`); value+rest tuple-unpack/
return/aug-assign + `heapreplace`; pure lowering for early-return; `pyany_cases` in `taste?`;
**`float('inf')` sentinel** `10^30` (was stub `-1` — `maximize-the-beauty-of-the-garden` 112/126 →
126/126); **`str.format` spec parser** + `str.zfill`; **unified in-place-mutator statement handler**
(`statementMutatorRebuild?` — `clear-digits` `"a1b2c"→"c"`, covers pop/insert/reverse/extend); native
eval architecture (one `lake build` for all harnesses); TypeInfer engine (P0 consolidation + read/write
numeric-container inference). See `[[compile-fail-typeclass-taxonomy]]` `[[runtime-api-fixes-batch]]`
`[[native-eval-architecture]]` `[[typeinfer-engine]]`.
