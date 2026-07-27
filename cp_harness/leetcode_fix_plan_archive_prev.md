# LeetCode sweep plan — 2026-07-26 (multi-agent analysis)

**Mandate: NO new features. Sweep the 489 conversion failures + 78 wrong answers + 106 timeouts.**
Built from a 4-agent analysis of the overnight run (`overnight_leetcode.log`, convert stage through
commit `25d3297`). Full per-cluster problem lists in the scratchpad reports
(`report_compile.md`, `report_convert_clusters.json`).

## Snapshot

Convert (2589 problems): **ok 2100 · compile_fail 404 · convert_fail 85** → **489 to fix**.
Eval (2001 compiled + tested): **all-pass 1790 · timeout 106 · partial 71 · no_passed 7 · no_test 27**.

## Why only +~100 net despite ~10 commits (regression verdict)

**Every function is emitted twice** — provable twin `foo` + runnable twin `foo'rn`, both must compile.
Yesterday's headline commits (`c277a33` Array-back, `993840e` memoize, `c082378` class-suffix) all
rework the **run twin**, which added a fresh compile-failure surface roughly as fast as new problems
converted:
- **~66 run-twin boundary coercions** — `Option TreeNode` (prove) vs `Option TreeNode'rn` (run)
  mismatches; 78 files touch Trie/ListNode/TreeNode. + **6 Array-vs-List** clashes (`c277a33`).
- **Numeric-tower churn** (self-admitted in commit bodies): the `inf`→ℚ sentinel over-widens integer
  reassignments / floor-div → 37 ℚ/ℤ clashes + 6 `invalid-reassign ℚ` + 5 units-div.
- Estimated **~60–90 regression-attributable compile_fails** — enough to cancel the prove-side gains.
- **Memoization fired on 1 of 29** `@cache` timeouts (falls back whenever the recursive call sits in a
  lazy position — `a or dfs()`, `max(dfs() for …)` — which is how real DP is written). So the run-twin
  infra largely **didn't fire where it was meant to help**.

**Lesson for the sweep:** prefer fixes that help BOTH twins or are twin-agnostic; when touching a twin,
check the other still compiles. Reconciling the twin-boundary class coercions (node_option cluster)
directly reverses channel 1.

## §W · WRONG ANSWERS (78: 7 no_passed + 71 partial) — highest priority

### W0. The divergence detector is BLIND — harness fix [EASY, do first]
Overnight reported "divergences: 0" — a **false negative**. Every LeetCode `eval/sol_0.json` has
`"python": null` (Python is skipped), so the check `if lean_pass < py_pass or (err and py_total)`
(`cpasta_eval.py:1391`) can never fire (`py_pass=py_total=0`). The pass/total in the log come from a
**separate expected-answer oracle** (`cases[i][1]`) — which is why 78 problems visibly fail while the
divergence bucket stays empty. **Fix:** also flag a divergence when `lean_pass < lean_total` against the
expected-answer oracle (already loaded; per-test `{args, expected, lean_got}` already on disk — no
reruns to debug). Without this we are blind to every wrong answer.

### W1. Union-find / DSU path-compression clobber (7 no_passed + ~8 partial) [FIXED this session]
`p[x] = find(p[x])` in a threaded nested `find`: codegen emitted the compression write
`p := pySetItem p x (fst)` and THEN the state-restore `p := snd`, which **clobbered** it — so `find`
returned the immediate parent, not the root, for any chain ≥2. **Fix (`Core/Assign.lean`):** for a
`_thread_unpack` combined assign, emit the threaded-name restores (indices ≥1) BEFORE the user target
(index 0), so the subscript write lands on the restored container. General for any `thr[i] = helper(…)`
inside a threaded helper. Clears: graph-valid-tree, redundant-connection(-ii),
number-of-operations-to-make-network-connected, optimize-water-distribution, process-restricted-friend-requests,
valid-arrangement-of-pairs, + partials most-stones-removed, satisfiability-of-equality-equations,
number-of-islands-ii, similar-string-groups, sentence-similarity-ii, the-earliest-moment-…,
connecting-cities-…, graph-connectivity-with-threshold. **Verify with the W0-fixed detector.**

### W-buckets (remaining partials, after W1) — verify with W0 detector
- **B2 mutation-not-persisting across iterations** — flipping-an-image, pacific-atlantic-water-flow,
  projection-area-of-3d-shapes (grid in-place row edits lost).
- **B3 graph BFS/DFS traversal** — bus-routes, all-paths-from-source-lead-to-destination,
  course-schedule, is-graph-bipartite (visited set/queue mutation across iterations; overlaps B2).
- **B4 str format-spec** — similar-rgb-color (`#999999`→wrong), lexicographically-smallest-string.
- **B5 unicode whitespace in split()** — reverse-words-in-a-string (`\xa0`).
- **B6 big-int at 2^64** — apply-discount-to-prices (int going through a 64-bit/Float path).

## §C · COMPILE_FAIL (404, 22 clusters) — ranked sweep

| # | cluster | n | root cause | fix location | diff |
|---|---------|---|-----------|--------------|------|
| C1 | **class_slots** | 17 | `__slots__=[…]` emitted as a real ℤ field | `PyGens/UseCases/ClassDef.lean` (drop it) | **easy** |
| C2 | **bisect_key** | 35 | `bisect_left/right(…, key=fn)`, `nlargest(…, key=)` — shims lack `key=` | `Libraries/bisect/*`, `Libraries/heapq/*` + kwarg wiring | med |
| C3 | **sortkey_neg** | 15 | `key=lambda x:-x[1]` — `x` untyped → `Neg β`/`Ord β` | TypeInfer key-lambda param from iterable + `LambdaExpr.lean` | med |
| C4 | **tuple_subscript** | 25 | `(String×ℤ)` indexed `x[0]` — no `PyGetItem (Prod) ℤ` | `CommonProtocols/GetItem.lean` + TypeInfer tuple | med |
| C5 | **numeric_dual** | 36 | ℤ binding later gets ℚ/Float (or `x/y`→ℚ into ℤ slot) | `TypeInfer/Solve.lean` widen containers+reassign | med |
| C6 | **defaultdict_counter** | 21 | defaultdict where HashMap expected; `PyDelItem`/BEq gaps | `Libraries/collections/*` + TypeInfer (25d3297 PARTIAL) | med |
| C7 | **pyany_fallback** | 20 | uninferred param/container stays PyAny | TypeInfer seeding (b8f28b4 likely PARTIAL — RE-RUN) | med |
| C8 | **string_method_arg** | 19 | `s.rfind(x,0)` over-applies; find/index/count lack start/end | `PyAPI/Strings.lean` + `Attributes.lean` | med |
| C9 | **node_option** | 62 | `.next/.val` on `Option`, `Option X→X` reassign, `PyTruthy ListNode`, `None`-default→Unit | TypeInfer + `PyGens` Option-lift (c082378 PARTIAL) | hard |
| C10 | **closure_helper** | 26 | nested `dfs` sibling def fails → `Unknown identifier` cascade | `ClosureConvert.lean` (mostly a cascade of an inner bug) | hard |
| C11 | **trie_class_attr** | 9 | `self.children` dict → PyAny recursive class | b8f28b4+C1 PARTIAL — RE-RUN | hard |
| — | tail | ~100 | pyiterable_elem 12, decidable_struct 9, infer_binder_helper 8, math_lib 6, unsupported_lib/SortedList 9, mutate_shadow 7, ambiguous_ident 3 (easy), match_metavar 3, bitops 4, MISC 52 | | mixed |

**Recommended C-order today:** C1 (easy, 17, also unblocks Trie/tree classes) → C2 (35, self-contained)
→ C3+C4 (~40, reinforce on the same `x`) → C5 (36) → C9 (62, hard but biggest & reverses regression
channel 1). RE-RUN C7/C11 against `b8f28b4` before investing.

## §V · CONVERT_FAIL (85, 4 meta-clusters) — codegen throws before compile

- **V1 nested/mutual-recursion threading (31, hard)** — helpers mutating captured vars across a `mutual`
  block (13), called from pure positions (comprehension/lambda/while-test) (9), needing type annotations
  (5), using `nonlocal` (4). `ClosureConvert.lean`. The read-only-helper-in-comprehension subset can
  lower pure (MEDIUM) — partial win.
- **V2 unsupported library members (23, additive)** — bisect (10, ↔C2), qualified `heapq.*` (3, EASY —
  shim exists, just unwired), itertools/functools (3), setdefault/date/re.sub (5).
- **V3 mutating-method value-semantics (13, MEDIUM)** — `pop()`/`union()`/`popleft()` as a
  sub-expression; needs the hoist pass `[[value-rest-mutating-calls]]` already flags. `Pop.lean` + call
  lowering. ~11 problems.
- **V4 codegen node gaps (11)** — `null` tuple-return annotation (4, maybe c082378-fixed), `obj[i].attr=`
  (4, hard), walrus-in-BoolOp/while (4, hard), strided slice-assign (2), for-target subscript (1,
  `ControlFlow.lean` — accounts-merge).

## §T · TIMEOUTS (106) — correct-but-slow (103/106 passed some tests first)

- **T1 `@cache` lazy-position fallback (28, biggest lever)** — memo lowering falls back when the
  self-call is in and/or/ternary/`max`-generator/comprehension. Extend memo lowering to those positions
  (materialise the generator / pure HashMap-threaded fold instead of a `(←…)` hoist).
- **T2 List-backed O(n²) run twins (~90)** — only 8/106 got Array-backed; rest use `List` O(n) ops +
  `ℚ` arithmetic + `StateM`. Widen Array eligibility; default integer DP to `Int`.
- **T3 inherent exponential / huge test totals** — not codegen-addressable.

## §N · NO_TEST (27) — HARNESS coverage, NOT codegen [EASY harness wins]

- **N1 in-place `-> None` mutators (15)** — compile fine; harness scores the `None` return instead of
  the mutated argument. **Fix `cpasta_eval.py`: for `-> None` solutions, compare the mutated input arg.**
  duplicate-zeros, game-of-life, merge-sorted-array, move-zeroes, next-permutation, reverse-string,
  rotate-array, rotate-image, set-matrix-zeroes, sort-colors, surrounded-regions, walls-and-gates,
  wiggle-sort(-ii), reverse-words-in-a-string-ii.
- **N2 tree/linked I/O (2)** — harness can't build TreeNode. N3 value-returning-but-0-tests (10) —
  harness failed to locate their input files.

## TODAY's sweep order (no new features)

1. **W0 divergence detector** + **N1 `-> None` scoring** — harness fixes; make wrong answers measurable
   and recover 15 no_test. [EASY]
2. **W1 union-find reorder** — DONE, verifying (~15 wrong answers). [DONE]
3. **C1 class_slots** (17) → **C2 bisect_key** (35) → **V2 heapq wiring** (3). [EASY/self-contained]
4. **C3+C4 sortkey/tuple_subscript** (~40) → **C5 numeric_dual** (36).
5. **RE-RUN convert** to re-measure after b8f28b4 + today's fixes (C7/C11/trie likely improved).
6. Only then the hard clusters C9 node_option / C10 closure_helper / V1 threading.

## Done this session (committed)
- `b8f28b4` class-method param inference (types `def C.method (x:Int)` from call sites) — sweeps class
  compile_fails; NOT in the 2100 (re-run to measure).
- `ec9757b` harness error verbosity — `summarize_error` keeps the full first diagnostic (type/instance),
  so `errors_by_frequency` distinguishes clusters. (This analysis used the FULL per-problem `.log` files.)
- (uncommitted) W1 union-find `_thread_unpack` restore-before-write reorder — verifying.

## §R · DEFERRED REFACTOR — ShimSpec registry (not today; own focused session)

Today each library function is hand-wired across FOUR disconnected places: name→fn
(`Libraries/*/Mapping.lean`), return type (`TypeInfer/Rules.lean builtinReturn` — a hardcoded match,
NOT the registry), mutation kind (`Libraries/Mutator.lean` + `Attributes.lean`), and kwargs/`key=`
(scattered `CallExpr` special-cases). Adding a function touches all four. Proposed fix: ONE
`ShimSpec` descriptor per member —
`{ leanFn, arity, kwargs (key/lo/hi/reverse + keyed-variant), returns (const|fromArg|elementOf|custom),
effect (pure|mutates|value+mutation), argTypes (e.g. key-param = element type of arg 0), lower? hook }` —
read by BOTH codegen (dispatch/kwargs/key=) and TypeInfer (return + arg-type propagation). Subsumes the
library clusters (bisect/heapq/itertools/functools/collections/string/math, ~80-100 problems + all
future shims) and turns today's `key=` param-PyAny bug into a one-line `argTypes` rule. Does NOT touch
the core-language clusters (node_option/numeric/closure/tuple), which are the bulk of the 489 — so it's
a maintainability + shim-coverage win, scheduled separately from the sweep.

## §TALLY · Problems potentially fixed today (2026-07-26 sweep) — target >300

Measured on the affected problems (convert OK = out of compile_fail; full-pass = wrong-answer fixed).
Not yet a full-corpus re-run (that's the overnight job).

| fix | cluster | measured | note |
|-----|---------|---------:|------|
| union-find `_thread_unpack` reorder (de91948) | §W1 | **+11** | of 15 DSU; 4 remain (separate bugs, now flagged by the fixed divergence detector) |
| class_slots `__slots__` drop | C1 | **+6** | of 17 convert OK; 11 remain (deeper Trie/Node cluster C11) |
| bisect `key=` keyed-variant routing | C2 | **+16** | of 35 convert OK; 12 remain = key-fn param `PyAny` (→ stampKeyLambdas / key-callback refinement), 2 = heapq nlargest key= |
| stampKeyLambdas (key-lambda param = element type) | C3 sortkey | **+14** | of 15 convert OK; also unblocks the list-element tuple_subscript cases |
| class-method param inference (b8f28b4) | C7/C11 | *pending* | committed pre-sweep; needs a re-run to attribute |
| stampKeyLambdas (list-element key-lambda) | C3 sortkey | **+14** | of 15 convert OK |
| tuple key-param static projection | C4 tuple_subscript | *partial* | static `Prod.fst/snd` works, but downstream comprehension-unpack + `LinearOrder (ℤ×ℤ)` still block many — clean re-measure pending |
| string find/rfind/index start/stop params | C8 string_method | **+2** | of 19; rest entangled with Option-String/join gaps |
| tuple_subscript root fixes (bisect→Ord, comprehension `_pair_ty` ascription, chain/product rules) | C4 | **+3** | of 25 directly (find-right-interval, merge-similar-items, sort-characters); the SAME fixes power sortkey (+14) & generalize. Remaining 22 = distinct per-problem tails (starred-unpack, direct tuple-compare, list-Assign-unpack) |
| PyDefaultDict PyTruthy + PyDelItem instances | C6 defaultdict | **+5** | of 21; rest need dict-equality/Counter-merge/PyAny-key |
| node_option foundation + desugar-before-infer | C9 node_option | **~9+** | PyTruthy(class)/Coe C→Option/ascribe-nullable-local/run-suffix + chained-assign now typed (middle-of-the-linked-list, reverse-linked-list). Remaining: consistent Option-flow both directions, nested `.next.next` unwrap, Decidable node-eq, tuple-of-nodes |
| desugar-before-inference (chained assign typed per-target) | numeric_dual + broad | **+2 (num) + broad** | car-fleet, middle; corpus-wide chained-assign fix |
| heappop/heappush TypeInfer typing (element type / mutation) | numeric_dual | **+3** | numeric_dual 2→5; unblocks numeric widening through heaps (dist=list ℚ). Documented design-choices §27; regression example_scripts/typing/numeric_widening.py |
| **numeric_dual remaining (~31)** | C5 | — | RETURN reconciliation (`ans : ℚ` — nested-def `-> int` unascribed, `return inf` defaults ℚ), bool→int SetItem, nested-tuple-float heap (KNOWN GAP, §27), transcendental `** 0.5`. Each a subtle individual facet |
| **RUNNING TOTAL (cluster-measured)** | | **~90** | union-find 11 + class_slots 6 + bisect 16 + sortkey 14 + string 2 + tuple 3 + defaultdict 5 + node_option ~9 + (method-inference & broad key-lambda/comprehension fixes help beyond their home clusters) |

**Measurement hygiene (learned today):** NEVER run a `convert` measurement while `lake build py2lean`
is in flight — the compile-check races the `.olean` rewrite and reports bogus "object file … does not
exist" failures (`[[py2lean-build-race]]`). A random 60-sample was invalidated this way; re-running
clean. Extrapolation target: the sample estimates the whole-404 recovery rate for a full re-run.

TOTAL = ?? 


## §ESTIMATE · Honest whole-corpus projection (clean 60-sample)

Random 60 of the 404 compile_fails, re-converted with ALL of today's fixes (build-race-free):
**8 OK (13.3%)** → extrapolated **~54 compile_fails** recovered across the full 404. The 8 are all in
today's clusters (sortkey/bisect/class_slots), confirming the fixes generalise.
- compile_fail recovered: **~54** (of 404)
- wrong-answer recovered (union-find): **~11** (of the DSU 15)
- **TODAY'S TOTAL (projected): ~65 problems** — well short of the 300 stretch target.

The remaining ~350 compile_fails are dominated by HARD core-language clusters a shim/lambda fix can't
touch: **node_option (62), numeric_dual (36), closure_helper (26), tuple_subscript downstream (25),
defaultdict_counter (21), pyany_fallback (20)**. Each is a substantial standalone fix. Reaching 300
needs several of these landed — realistically multi-day, not one sweep. The verified per-fix wins today
(union-find correctness, sortkey, bisect key=, class_slots, string start/stop) are solid and low-risk;
the number is just smaller than hoped because the failure tail is genuinely hard, not shallow.

## §FOUNDATIONAL FIX (2026-07-26 afternoon) — desugar BEFORE inference

The `inferTypes` backend task ran `lowerGenerators + inferModule` but NOT `desugarAst`, so inference
saw the un-split `a = b = expr` (a multi-`targets` node it can't learn per-target from). Codegen then
desugared it (`splitChainedAssign`), stripping the stamps inference would have produced. Fix
(`py2lean.lean`): `inferTypes` now runs `lowerGenerators → desugarAst → inferModule`, and the translate
task skips both passes when `_inferred` is set (no double-desugar). Plus `splitChainedAssign` now
duplicates a LITERAL RHS to each target (no shared temp) so `ans = pre = 0` types each independently.
Recovers `car-fleet` (`pre : ℚ` from `pre = a/b`), `middle-of-the-linked-list` (`slow = fast = head`
chained → Option cursor), and broadly anything with chained assign across clusters. HIGH blast radius —
the whole corpus now infers on the desugared IR; verify against the overnight regression run.

## §NODE_OPTION FIX (2026-07-26 afternoon) — run-suffix classes inside `Option`/containers

`FuncDef.functionArgTypeSyntax?` ascribed `Optional[T]` and `X | None` params (and return types) via
`pyTypeSyntax? ∘ ofAnnotation`, which is context-free and does NOT run-suffix a class name — so a param
`head: Optional[ListNode]` became `Option ListNode` (prove name) while the run twin's body built
`ListNode'rn` values → "Option ListNode but expected Option ListNode'rn". Fix: route both fallbacks
through `seqAwareTypeSyntax?` (which recurses via `runAwareTypeSyntax?`, suffixing the class inside
`Option`/`List`/`Set`, and keeps `_seq` array-marking). **node_option 20-sample: 3 → 9 ok (+6).**
Scales across the 62-problem cluster (Optional node params/returns are ubiquitous) → est. **~18 corpus**.
Newly OK: construct-bst, convert-sorted-list, merge-nodes, odd-even, remove-nodes, rotate-list.
Remaining node core = `Option Node` passed to a helper whose param is bare `Node` (interprocedural
param-widening + in-body unwrap) — the genuinely hard part, deferred.

## §NODE_OPTION CLUSTER PUSH (2026-07-26 evening) — 6 structural fixes, ~50→38 failing

Full node-referencing set = **152** problems (superset of the 62-failing cluster). Baseline this
session ~102 ok. After six fixes: **114/152 ok (75%)**. All are general (help beyond nodes):

1. **run-suffix through `Option`** (FuncDef `functionArgTypeSyntax?`): `Optional[C]` params/returns
   route via `seqAwareTypeSyntax?` so the class inside `Option`/containers is run-suffixed
   (`Option ListNode'rn`). [+6 in the 20-sample] — [[twin-suffix-through-option]]
2. **nullable param-widening** (Solve `paramSeed`/`nameIsNoneTested`, skips nested defs): a bare
   node-class param the body tests `is None` widens to `Optional[C]` (LeetCode writes `root:TreeNode`,
   means `Optional`). Split `_mut_opt` (reassigned cursor) vs `_ty` override (pure recursive dfs).
3. **Option-codomain return ascription** (FuncDef `returnClassName?`, both recursive + non-recursive):
   a node-returning fn's codomain is `Option C` (bare arms coerce via `Coe C (Option C)`), never bare.
4. **class comparison via `BEq`** (Basic `_class_cmp`, stamped in Solve `markOptAttrs`): node `==`/`is`
   emit `==`/`!=` even in the exact twin — nodes derive `BEq` but not `DecidableEq` for a
   propositional `=`. [cleared the Decidable bucket, ~7]
5. **node tuple-unpack coercion** (Assign `tupleElementAssignDoElem`): `↑` on a projection into an
   `Option C` mut-cursor target (`tl, tr = (l, r)`) so it elaborates at `C` then lifts, instead of the
   ascription back-unifying the polymorphic `Prod.fst`. [cleared the unpack_pair bucket, ~6]
6. **cross-scope capture mutations** (Solve `applyCaptureMutations`): a container mutated in a nested
   def (`nums.append(x)` / `nums[i].append(x)` in `def dfs`) refines the outer binding, so a sibling
   `def build` reading `nums[i]` sees `List Int`. Shadow-guarded (join-only).

Remaining ~38 = the hard tail, NO single-fix bucket left: untyped nested-container ascription +
defaultdict-key inference (general), `Array`/`List` backing reconcile (numeric, not node), recursive
tuple-return + state-threading dfs (maxSumBST/largestBST/minCameraCover), `Hashable` node-as-dict-key,
tuple-index-on-a-call (`dfs(root)[0]`), and one-offs (`setattr`, mutual-recursion `nonlocal`). Each is
a standalone effort or a general subsystem, not a shaped cluster.

## §DFS / MUTUAL-RECURSION CONVERT-FAILS (2026-07-26 late) — 31 convert-fails → 23 convert, 12 ok

The two "dfs" convert-fail buckets (22 mutually-recursive + 9 threaded-call-in-comprehension) were the
hardest structural convert-fails. Three ClosureConvert changes, all general + regression-checked
(closures/decorators/lambda/captured_containers/list_comprehension all still translate):

1. **SCC grouping, not weakly-connected** (`nestedRefComponents`): nested defs cluster by directed
   *strongly-connected* components of the call graph, topo-ordered callee-first. Only a genuine
   reference CYCLE needs a `mutual` block; union-find's `union → find` is a DAG, so each lifts through
   the normal threading-capable `liftHelper` — no longer rejected. A lone `find` with path compression
   (`p[x]=find(p[x])`) already threaded; this unblocks the pair.
2. **Cross-helper threading** (`ThreadedSpec` registry threaded through `closureConvertFunction` →
   `liftHelper`): a later-lifted helper (`union`) threads its calls to an earlier threaded sibling
   (`find`) — rebinding the shared `p` — and folds that sibling's threaded state into its own. Plus:
   `rewriteThreadedStmts` now skips nested `FunctionDef`s (a sibling's own scope), and the lift loop
   re-reads each cluster member from the LIVE `current` (so a read-only sibling `check`→`_check`
   rewrite done by an earlier lift isn't lost to the stale `nested` snapshot).
3. **Short-circuit comprehension expansion** (`expandThreadedComprehension?`): `sum(A and dfs(…) …)` /
   `all(c or dfs(…) …)` — a threaded call in the guarded second operand — lowers to an `if A` per-item
   body so `dfs` runs only in its branch, preserving BOTH the accumulator and the short-circuit.

Result on the 31: **12 ok, 11 compile_fail (converted, downstream type errors: threaded-tuple types,
universe-levels void-mutation, slices), 8 convert_fail**. The union-find cluster (~10) fully converts;
several compile. Remaining 8 = the hard tail: threaded call inside an `IfExp` condition
(evaluate-division), a `lambda` (checking-existence), a `while` test (path-with-maximum-minimum-value),
and TRUE mutual recursion (web-crawler-multithreaded, chessboard) — each a distinct further step.

### DFS follow-up (2026-07-26, fixing the 8+11 tail)
Two more general ClosureConvert/TypeInfer fixes (dfs cluster now **13 ok / 10 compile_fail / 8 convert_fail**):
- **transitive capture forwarding** (`liftHelper`): a helper must capture its called siblings' captures
  to FORWARD them — `eval` passes `parseVar`'s `n` though it never names `n` (fixed "Unknown identifier n").
- **array-backing excludes captured-mutated lists** (`listUsePorted`/`mutatesNameWithin`): a list
  MUTATED inside a nested def is threaded as `List`, so it must not be `Array`-backed (fixed restore-ip's
  `List String` vs `Array String`). A read-only capture stays `Array`-eligible.

Remaining 18 are distinct deep features, NOT a shared bucket: mutable-PARAMETER threading (`push(pq,x)`
mutates its arg — count-nodes, min-operations PUnit); numeric-sentinel × threading tuple reconcile
(`inf` in a threaded tuple return — beautiful-pairs); defaultdict element typing through captures
(parse-lisp scope, minimize-trips); param/None-list inference (next-closest, sliding-puzzle); PyAny
Decidable (preimage); and the 8 threaded-call-in-lambda/while/comprehension/true-mutual convert-fails.

### DFS follow-up round 2 (2026-07-27) — mutable-param threading + comprehension hoists
Five more general ClosureConvert fixes; dfs cluster now **15 ok / 10 compile_fail / 6 convert_fail**
(25/31 convert, from 0). Regression-clean (closures/list_comprehension/decorators/captured_containers/
union-find intact).
- **Mutable-PARAMETER threading**: an original param mutated IN PLACE (`push(pq,x)` heappushes pq;
  `swap(arr,i,j)` does `arr[i],arr[j]=…`) is threaded on the RETURN, and each caller rebinds the
  ARGUMENT in that position (`l := _push l x`). `ThreadedSpec.origParams` + `threadedTargetsFor` map a
  threaded param name → its call argument. `jsonMutatesInPlace` (subscript/attr/tuple targets +
  mutating methods + heapq free-fns `heappush`/`heappop`/…) — excludes bare rebinds (a param rebind
  never reaches the caller). Fixed count-nodes, min-operations (the PUnit-void cases).
- **Nested short-circuit comprehension**: refactored the short-circuit expansion into shared helpers
  (`shortCircuitOpOf?`/`comprPerItem`/`comprThreadable`/`comprLoopStmts`) used by BOTH the top-level
  expand and the nested `hoistThreadedComprs`, so `1 + sum(A and dfs(j) for j)` converts (reachable-nodes).
- **If-test comprehension hoist**: `if any(dfs(v) for v):` hoists the accumulator loop before the `if`
  (converts strange-printer-ii). `while` tests still can't (re-evaluated each iteration).

Remaining 6 convert_fail = the hardest threading: find in a `lambda` (checking-existence) / a `while`
test (path-with-maximum) / an `IfExp` condition (evaluate-division), a list-building ListComp with a
threaded call (contain-virus, number-of-valid), and fetch-mutates-captured-AND-used-as-value
(web-crawler). Remaining 10 compile_fail = numeric-sentinel×threaded-tuple, defaultdict-through-capture,
PyAny, param/None-list inference — each a distinct subsystem.

### DFS follow-up round 3 (2026-07-27) — the last 6 convert_fails + regression tests
dfs cluster now **18 ok / 11 compile_fail / 2 convert_fail** (29/31 convert, from 0). Four more general
ClosureConvert/Desugar fixes:
- **Precise comprehension/lambda rejection** (`callInsideContexts`): the threaded-call-in-a-lambda/
  comprehension reject now checks the call is ACTUALLY inside such a node, not that the statement merely
  contains one — `for … in sorted(xs, key=lambda …): … find(u) …` has both but `find` threads fine.
  Fixed the false positives (contain-virus, checking-existence, number-of-valid).
- **While-test threading**: `while find(a) != find(b):` → `while True: <thread test>; if not test: break;
  <body>` (the test re-runs each iteration). Fixed path-with-maximum.
- **Full-slice assign on a non-name container** (Desugar `rewriteFullSliceAssign`): `row[:] = xs` →
  `row = xs`. Fixed number-of-valid's `dist[i][:] = …`.
- **IfExp-condition short-circuit lowering** (`ifExpCondLower?`): `[X if (A or … or find(…)) else Y for
  …]` — `find` in the guarded last operand of the condition's chain — lowers per item to `cond =
  <prefix>; if not cond: cond = <last>; append(X if cond else Y)`, keeping the short-circuit (find never
  runs when `p` lacks the key). Fixed evaluate-division's THREADING (it now blocks on `defaultdict()` /
  `defaultdict(lambda)` factories — a SEPARATE cluster, not dfs).

Remaining 2 convert_fail are NOT dfs/threading: evaluate-division needs empty/lambda defaultdict
factories; web-crawler-multithreaded uses `threading.Thread(target=fetch)` (a mutated-capture closure
as a thread callback) — a concurrency-library case outside the threading model.

Regression tests: `example_scripts/general/closure_threading.py` (10 functions, PALC compile-checked) —
union-find (SCC+cross-helper), while-test threading, mutable-param heappush, tuple-subscript swap,
short-circuit + if-test + IfExp-condition comprehensions, transitive capture, false-positive lambda,
full-slice assign.
