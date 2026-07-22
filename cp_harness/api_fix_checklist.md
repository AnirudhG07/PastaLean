# API-fix & performance checklist (mimic Python behaviour, incl. complexity)

Goal: make the transpiler match Python semantics AND complexity so the leetcode corpus stops
timing out / diverging. Track progress here.

## D. CONVERT/COMPILE-FAIL LANDSCAPE (overnight full run: 1531 ok / 801 compile_fail / 257 convert_fail)

Extracted from per-problem `lean/sol_0.log`. NOTE: overnight data predates this session's fixes
(list-concat, operator instances incl. `PyHAdd Bool Bool Int`, division/float-cast defaults, pyRange,
negative bitwise, set comparison, for-target, `or`/`and` value, mutual recursion) — so some buckets
are already smaller. 6 agents diagnosing (results appended below).

**COMPILE_FAIL buckets (801):**
- [~] **D1. Application type mismatch** (190) — PARTLY FIXED. Two root causes closed:
      (a) **class container fields defaulted to `Int`** — `classStructFieldSyntax` typed a field via
      `ofValue` (literal shapes only), so `self.p = list(range(n))` (a *Call*) fell back to `Int` and
      every later `self.p[x]` cascaded into `PyGetItem ℤ ?m` stuck errors. TypeInfer now collects
      class field types (`classFieldSigs`, typing the initialiser with `typeOfExpr` under the
      `__init__` params) and writes them into the field's empty `annotation`, which the struct
      codegen already prefers. GUARD: types that mention a user class are NOT stamped — the run twin
      renames `TreeNode`→`TreeNode'rn` and only the codegen's class-name path applies that suffix.
      (b) **self-recursive methods** (`UnionFind.find` path compression) had no termination proof;
      now emitted `partial def` (and without `@[simp]`, the recursive-unfolding hazard).
      Also fixed: `stampNodeWith` read a ClassDef's methods from `"body"`, but the IR uses
      `"methods"` — so class methods were never type-stamped at all. (was: — Bool/Float/tuple in an ℤ position; xor-queries, construct-binary-tree-from-string.
- [~] **D2. typeclass stuck** (73) — LARGELY FIXED. Root cause: a nested def's captures are lifted
      into real parameters, and Lean will not infer a `def`'s param types from its body, so an
      un-inferred capture becomes `PyGetItem ?m …` stuck. Five inference gaps fed it, all closed:
      1. `applyStmt`'s `For` case used `nameId? target`, which is `none` for a TUPLE target — so
         `for a, b in pairs` bound NOTHING, and anything indexed by `a`/`b` stayed unknown. Now uses
         the existing `bindTargetType` (which already distributes over tuples).
      2. `needsAscription` was `false` for `.dict`, so a dict local was never ascribed → captured
         untyped. Now true when key AND value are concrete (mirrors the list/set rule).
      3. `counts[k] += 1` (AugAssign through a Subscript) taught nothing — a `Counter()`/`{}` never
         escaped `unknown`. Now learns both sides.
      4. `graph[k].append(v)` (mutation through a Subscript) taught nothing. `applyMutation` now
         attributes the learned type to the OUTER container's value slot.
      5. `d.get(k, 0)` ignored the DEFAULT argument, so `d[k] = d.get(k,0)+1` could never break out
         of `unknown`. `get`/`pop`/`setdefault` now join the default's type.
      Also: a module-qualified constructor (`collections.Counter()`) never reached `builtinReturn`
      because `library_module` was set and the registry has no type for it — a registry MISS now
      falls through to the builtin path.
      GUARD: a dict from a LIBRARY call is NOT ascribed — `defaultdict`/`Counter` are `PyDefaultDict`,
      not the `Std.HashMap` a `dict[_,_]` annotation emits; ascribing fought the real type.
      The `PyDefaultDict` gap is now CLOSED too — see PROGRESS update 6. Both named problems
      (sudoku-solver, valid-arrangement-of-pairs) compile clean. (was: — metavar in explicit arg (untyped binder); sudoku-solver, valid-arrangement-of-pairs. (division/float-cast partly fixed.)
- [~] **D3. Type mismatch** (53) — PARTLY FIXED: `float('inf')` in an INTEGER slot. Python compares
      `-inf` with ints freely; Lean needs one type. The sentinel is now polymorphic — `PyNonFinite`
      class with `ℚ` (default_instance), `ℤ` (`pyIntNonFinite`) and `Float` instances — so the slot
      picks it, and a top-level `inf = float('inf')` is emitted as a polymorphic
      `def inf {α} [PyNonFinite α] : α` rather than a monomorphic ℚ def. Applies in BOTH numeric
      modes now (approx previously took the `pyFloat` path, which broke an int DP the same way).
      tallest-billboard compiles; verified vs CPython (6/2/3.0). (was: — String/Bool/branch types; tallest-billboard, count-valid-paths-in-a-tree.
- [x] **D4. `PyHAdd Bool Bool`** (51) — VERIFIED FIXED (`PySummand` coercion; `sum(x!=y ...)` → Int).
      (was: — bool sum wants Bool not Int; height-checker, find-the-number-of-good-pairs-i. (may be fixed — added `PyHAdd Bool Bool Int`.)
- [ ] **D5. `PySetItem (List ℚ)`** (41) — int-list element defaulted to ℚ; greatest-sum-divisible-by-three, campus-bikes-ii.
- [ ] **D6. invalid reassignment** (40) — var rebound to conflicting type → should box PyAny; total-appeal-of-a-string, min-cost-to-connect-all-points.
- [ ] **D7. `PyContains PyAny`** (37) — `x in y` on PyAny/no-membership; longest-nice-substring, check-if-n-and-its-double-exist.
- [ ] **D8. Unknown identifier** (34) — missing builtin/method/field; sort-an-array, compare-strings-by-frequency-of-the-smallest-character.
- [ ] **D9. `PyIterable (ℤ×…)` / `PyGetItem (ℤ×ℤ)`** (29+16) — tuple iterated/indexed as list; spiral-matrix, advantage-shuffle.
- [x] **D10. Invalid field `.val`/`.left`/`.next`** (23) — FIXED. `typeOfExpr` had no `Attribute`
      case, so a chained receiver was `unknown` and the unwrap fired only on the OUTERMOST receiver.
      Added class-field types to `sigs` (`"Class.field"` keys, from each `ClassDef`, mirroring the
      struct codegen's `None`-default → `Option Class` rule) + an `Attribute` case in `typeOfExpr` +
      `PyType.classNameOf?`. Also made `attrRecordUpdateDoElem` Option-aware (unwrap + re-wrap in
      `some`), since `{ opt with f := v }` is not a valid record update.
      Verified vs CPython: `root.left.val`→2, depth→3, ListNode walk. (was: — Option TreeNode/ListNode unwrap; height-of-special-binary-tree, flatten-binary-tree-to-linked-list.
- [x] **D11. kwargs** (19) — `dict.get(k,d)`, `dict.pop(k,d)`, `dict.setdefault(k,d)`,
      `sorted(reverse=/key=)`, `min/max(default=)` all work now. (was: — `sorted(reverse=)`, `dict.get(k,d)`; reverse-nodes-in-k-group, minimum-falling-path-sum-ii.
- [ ] **D12. LinearOrder / PyTruthy on class** (12+8) — sorting/truthiness on a user type; process-tasks-using-servers.
- [ ] tail: Function expected (8), Invalid match (8), PyGetItem ℤ ℤ scalar-indexed (7).

**CONVERT_FAIL buckets (257 codegen throwErrors):**
- [ ] **D13. closure-as-value CAPTURING** (41) — `sort(key=helper)` where helper captures; needs `fun p ↦ new p caps`. number-of-beautiful-integers-in-the-range, house-robber-iv.
- [ ] **D14. tuple** (26) — recover-binary-search-tree, stone-game-vi.
- [ ] **D15. mutual recursion** (22) — sibling nested defs; MAY be fixed this session (typed); untyped still fails. beautiful-pairs, sliding-puzzle.
- [x] **D16. subscript-through-attribute** (21) — VERIFIED FIXED by `attrRecordUpdateDoElem`. (was: — `self.grid[i][j]=v` / `obj.arr[i]=v`; longest-word-with-all-prefixes, search-suggestions-system.
- [ ] **D17. generator-rebind** (15) — `dfs` mutating in a GeneratorExp; max-area-of-island, smallest-string-with-swaps.
- [ ] **D18. kwargs (convert)** (12), **walrus in BoolOp** (6).
- [ ] **D19. "other" convert-fail** (114) — UNCATEGORISED, needs fresh diagnosis. count-of-sub-multisets-with-bounded-sum, find-servers-that-handled-most-number-of-requests.

### Agent diagnosis (root cause + fix per problem) — appended as agents finish

**Agent 4 (type-mismatch + Option-field) — ROOT CAUSES:**
- **`for a,b in list_of_lists` typed as tuple** (xor-queries, minimum-area-rectangle-ii): codegen types the
  iter element `ℤ×ℤ` when it's actually `List ℤ` → `pyIter` expects `List(ℤ×ℤ)` got `List(List ℤ)`. The
  `_list_unpack` marker isn't firing here. Fix: infer list-of-lists element as list, unpack by index.
- **`float('inf')` in a TUPLE / branch splits the type** (tallest-billboard, binary-tree-cameras,
  minimum-area-rectangle-ii): inf is ℚ, so `(inf, x, y)` → `ℚ×ℤ×ℤ` but the recursive fn expects `ℤ×ℤ×ℤ`;
  or `if ans==inf then 0 else ans` has ℚ/ℤ branches. My inf fix (large ℚ sentinel) doesn't help when it
  must be ℤ. Fix: an Int-typed inf sentinel, or unify the branch/tuple element types.
- **`int(math.sqrt(...))` not casting before `//`** (count-...-dominant-ones): `pyFloorDiv` gets ℝ/Float,
  needs `pyInt` cast. Fix: floor-div should cast a Float/ℝ operand to ℤ.
- **Chained Option-unwrap on trees** (height-of-special-binary-tree, flatten, construct-binary-tree,
  balance-a-bst): a single `root.left` IS unwrapped (`(root).getD default`), but the RESULT of a
  `.left`/`.right` projection is itself `Option TreeNode` and the NEXT projection (`root.left.right`) or an
  aliased local (`pre = root.left`) is NOT re-unwrapped. Fix: recursive unwrap — every attribute step on a
  `TreeNode?`/`ListNode?` must `.getD default` before the next `.field`.
- **[CODEGEN BUG] `let mut root.left := …` is invalid Lean** (flatten, construct-binary-tree): attribute
  assignment through `pre.right = …` / `root.left = …` emits `let mut X.field := …`, not valid. Fix
  (`Core/Assign.lean`): emit a struct-update `pre := {pre with right := …}` + reassign the receiver.
- **User class method constants not emitted** (count-valid-paths-in-a-tree, similar-string-groups):
  `UnionFind.union`/`.find` referenced but no such constant generated (class-method dispatch naming), and
  `self.parent`/`self.rank` container fields untyped → `PyGetItem/PySetItem ℤ ?m` stuck. Fix: class codegen
  method-name emission + field-type inference. (similar-string-groups' `PyHAdd Bool Bool` likely fixed.)

**Agent 2 (numeric-container + bool-sum) — ROOT CAUSES:**
- **[CLEAR FIX] `sum(<bool generator>)` wants `PyHAdd Bool Bool Bool`** (height-checker, find-the-number-of-good-pairs-i,
  minimum-changes-to-make-alternating-binary-string, counting-words-with-a-given-prefix, minimum-adjacent-swaps):
  `sum(x != y for …)` lowers to `pySum (List Bool)`, fold accumulator inferred `Bool` → wants `Bool Bool Bool`
  (my `PyHAdd Bool Bool Int` does NOT cover this). **Fix in `pySum`/`sum` (`Builtins/Functional.lean`):
  summing a `List Bool` must yield `Int` (coerce each Bool→0/1 before folding, or count trues).** ~51 problems.
- **`float('inf')` in an integer DP table → `PySetItem (List ℚ) ℤ Float`** (greatest-sum-divisible-by-three,
  campus-bikes-ii, coin-path, optimal-account-balancing, make-array-non-decreasing-or-non-increasing):
  inf = `pyRatNonFinite` (ℚ) seeds the table → container `List ℚ`, but the write value is ascribed `Float` in
  the `'rn` twin → mismatch. Also inverted (container ℤ from `0`, value ℚ from `mi=inf`). NUANCE: primary def
  uses `: Rat` and COMPILES; only the **`'rn` twin picks `Float`** — primary/`'rn` twins choose different numeric
  types for the same write. **Fix: TypeInfer treat `float('inf')` as ONE canonical numeric type across the DP
  and BOTH twins so container-elem and write-value unify.** (My large-ℚ-sentinel inf fix doesn't address this.)

## A. Performance / timeouts — RE-DIAGNOSED: mostly SPURIOUS INFRA, not complexity

**Key finding (evidence):** the 11.9k "timeout" cases were NOT List O(n²). Fresh runs of "timeout"
problems are fast: decode-ways **176/176** (was `[timeout]`), trapping-rain-water 140/140,
palindromic-substrings 127/127, remove-duplicates 143/143, search-a-2d-matrix 128/128. ~80% were
spurious — caused by (i) a compile-check path bug marking compiling files as compile_fail, (ii) the
overnight disk-full crash (harness `.tmp` never cleaned), (iii) backend heartbeat poisoning. A
MINORITY (~20%, e.g. coin-change-ii: still times out even at 60s) are genuine heavy array-DP where
List O(n) indexing → O(n²). Array-backed would help only those. User chose to DEFER array-backed.

- [x] **A2/infra. compile_check path bug** — `compile_check` ran `lake env lean <rel-path>` from
      `cwd=REPO_ROOT` → spurious "no such file" compile_fail for a relative `--dataset`. Now resolves
      absolute. (cpasta_eval.py) **[FIXED — decode-ways convert 0→1 ok]**
- [x] **A2/infra. `.tmp` cleanup + disk guard** — harness `.lean` files accumulated in `.tmp` (never
      deleted) → the overnight disk-full crash. Now deleted after each eval (`run_lean_harness`),
      `.tmp` cleared + low-disk warning at convert/evaluate start (`_prepare_tmp`). **[FIXED]**
- [x] **A2/infra. Proactive backend reboot** — `WarmLeanEval.REBOOT_EVERY=400`: reboot before the
      ~1950 heartbeat-poisoning cliff. **[FIXED]**
- [x] **A4. BATCHED NATIVE COMPILE eval (the real fix, default)** — Mathlib ships native objects
      (`.c.o.export`, 8176), so harnesses CAN compile+run native (~1000× faster than the interpreter:
      heavy DP 0.055s vs timeout). But per-harness compile reloads Mathlib (~5s). Fix: emit every
      function harness as a namespaced module `CpHarness.H<id>` (`def run`), one dispatcher exe, and
      ONE `lake build` (Mathlib loaded ONCE, all 64 cores) → run each native binary invocation
      (instant, parallel, per-run timeout kills one run — no Mathlib reboot). `cpasta_eval.py`
      `_evaluate_native` (default; `--interpret` = old warm pool). 10 problems: 23s compile + instant
      runs. Idle placeholders keep `lake build` working. **[DONE]**
- [x] **A5. PARTIAL results on timeout** — harness flushes `PROG t p` per case; a native timeout now
      reports `18/124 [timeout@18/124]` (passed-so-far + where it hung) not a bare `0/124`. **[DONE]**
- [x] **A6. Parallel interpret pool** (`--interpret`) — pool of warm backends, serialized boots. **[DONE]**
- [ ] **A1. Array-backed sequences** (DEFERRED) — now LOW value: native compile already makes the
      genuine-slow DP instant. Only the truly pathological cases (exponential algorithm in one test
      input, e.g. coin-change-ii case 18) still time out, and Array wouldn't fix an exponential.
- [x] **A7. run-log noise** — the overnight log ended in ~790 lines of thread tracebacks. Cause: the
      forked reference child inherits the parent's stderr, and a dataset solution that spawns its own
      threads (web-crawler: `htmlParser.getUrls`) raises *inside those threads*, bypassing our
      try/except and hitting `threading.excepthook`. Fix: `_ref_stream_worker` redirects fd 1/2 to
      devnull, silences `threading.excepthook`, and `os._exit(0)`s so leftover non-daemon threads
      can't hold the child open. Also `load_callable` now execs dataset source under
      `warnings.catch_warnings()` (third-party `SyntaxWarning`s). Error reporting, hang-isolation and
      OOM-isolation all re-verified intact. **[DONE]**
- [x] **A8. don't eat every core** — this Lake (5.0.0) has no `-j`/`--jobs`, so build parallelism is
      capped by CPU affinity: `taskset -c 0-(jobs-1)` + `LEAN_NUM_THREADS`. Default
      `min(48, ¾·cores)` (48 on this 64-core box), overridable with `--jobs/-j`. Affinity is
      inherited by lake's spawned workers — measured 3190% → 396% under a 4-core cap. **[DONE]**

## B. Correctness / API bugs — DONE this session

- [x] `float('inf')`/`nan` sentinel (`pyRatNonFinite` was `-1` → large ℚ sentinel). ~10 problems.
      maximize-the-beauty 112→126/126.
- [x] `str.format` specs (`{:02d}`, positional, align, `{{}}`), `str.zfill`. binary-watch.
- [x] Unified in-place-mutator statement handler (`statementMutatorRebuild?`): pop/pop(i)/insert +
      existing append/clear/etc. clear-digits fixed.
- [x] Operator instances: List `+` concat, Char+Char/+String, modulo Rat/Float/mixed (floor),
      pow Float^Int/Nat^Int, PyHDiv/PyFloatCast untyped defaults.

## C. Correctness / API bugs — TO DIAGNOSE (agents) then fix

Non-timeout failing problems (52 wrong-answer + 10 non-timeout errors). Agents fill in root cause.
Mark [x] when the root-cause API is fixed & re-verified. (Some may already pass post-B — verify.)

### Known/suspected root causes (from earlier sampling)
- [ ] **set-comparison** (`s<=s1` subset, `set==set`): List-backed → List `≤`/BEq (wrong). Needs
      Compare codegen to know operand is a set (TypeInfer stamps `_ty` on binders only).
      Problems: keyboard-row, determine-if-two-strings-are-close, intersection-of-two-arrays,
      find-the-difference-of-two-arrays, intersection-of-three-sorted-arrays.
- [ ] **negative-int bitwise / two's-complement** (`num & 0xffffffff`): convert-a-number-to-hexadecimal,
      adding-two-negabinary-numbers, find-the-original-array-of-prefix-xor(?).
- [ ] **`0/N` systematic** (whole solution wrong): concatenation-of-array, apply-discount-to-prices,
      distribute-elements-into-two-arrays-i, minimum-index-sum-of-two-lists, latest-time-…, pascals-
      triangle, partition-array-into-two-…, minimum-seconds-…, find-the-minimum-area-…

### Agent diagnosis results — CONSOLIDATED (6 agents, 60 problems)

**~23 NOW_PASS** from this session's fixes (stale eval JSONs): intersection-of-three-sorted-arrays,
concatenation-of-array, distribute-elements-into-two-arrays-i, minimum-index-sum-of-two-lists,
find-the-original-array-of-prefix-xor, partition-array-according-to-given-pivot, asteroid-collision,
can-place-flowers, most-visited-sector, pascals-triangle, add-minimum-number-of-rungs,
distribute-candies-to-people, generate-binary-strings-without-adjacent-zeros, combination-sum-iii,
maximum-number-of-tasks, numbers-with-same-consecutive-differences, maximum-sum-circular-subarray,
count-unique-characters, minimum-string-length-after-removing-substrings, count-pairs-of-equal-substrings,
adding-two-negabinary-numbers, increasing-triplet-subsequence, minimum-average-difference.

**REAL remaining bugs (by frequency, ranked for fixing):**

- [x] **R1. `pyRange` 3-arg step off-by-count** (3: group-the-people, calculate-digit-sum,
      minimum-number-of-operations-k-periodic) — `Core.lean` count = `(d/step)+(d%step)` should be
      ceil `((d)+step-1)/step`. Trivial, high-confidence. **[FIXED]**
- [x] **R2. `a or b` / `a and b` return Bool, not the value** (2: convert-to-base-2,
      largest-palindromic-number) — `x or '0'` emitted `pyTruthy x || pyTruthy "0"` (Bool). Fixed with
      `boolOpValueTerm` (nested `if pyTruthy c then c else …`), wired into VALUE positions only
      (`Head_Return`, `Return` doElem, Assign RHS) so *condition* positions keep the Bool form (no
      golden churn). convert-to-base-2 69/69, largest-palindromic 50/50. Operands must share a Lean
      type (the common `<expr> or <default>` idiom). **[FIXED]**
- [x] **R3. `str.capitalize()` doesn't lowercase the tail** (1: capitalize-the-title) —
      `pyStringCapitalize` = Lean `String.capitalize` (keeps tail case). Trivial. **[FIXED]**
- [x] **R4. f-string numeric format spec `{h:02d}` emits `23.000000`** (2: latest-time,
      largest-time-for-given-digits) — `pyFormatSpec` ignores width/pad/`d`. Reuse the `pyStrFormat`
      spec logic. **[FIXED — pyFormatSpec now width/pad/precision/base-aware]**
- [~] **R5. `float('inf')` → Float return** — HARNESS GROUND TRUTH: mostly FALSE ALARMS. Agents used
      `pastalean run` (pyPrint), but the harness compares via Lean `==`/`repr`. Re-eval shows
      partition-array **130/130**, maximum-alternating **93/93**, minimum-seconds **116/116**,
      grid-game **88/88** all PASS. Only **maximum-sum-score** (0/118) + **minimum-cost-to-set-cooking-time**
      genuinely fail: the return type becomes `Float` (inf branch) but `expected` is `ℤ` →
      `inf.toFloat has type Float but expected ℤ`. Real fix (2 problems): keep an inf-seeded integer
      function's return `ℤ`/`ℚ`, don't let `_ret_float` widen it. LOW priority (2 problems).
      LESSON: agent "WRONG" verdicts on numeric problems are unreliable — verify via harness.
- [x] **R6. for-loop target reassigned inside `if` → reset to `default`** (3: goat-latin,
      number-of-steps-to-reduce, apply-discount-to-prices) — codegen emitted `let mut w := default`
      shadowing the loop binding. Fixed: `forTargetBinder` now emits `let mut w := <loopval>` +
      `addVar` for a reassigned Name OR tuple-element target (`bodyReassignsName`). goat-latin →
      correct, number-of-steps → 14, `['a','BB','c']`. **[FIXED]**
- [x] **R7. set subset/equality** (2: keyboard-row `<=`, determine-if-close `==`) — List-backed sets
      used List `≤`/BEq (order-dependent). Fixed with codegen-level set tracking: `setVars` in PyGen
      State (scoped by `withFixedVariables`/`withFreshVariables`), `jsonIsSetExpr` (set() call, `{…}`
      literal, set-op, or a tracked set var), Assign marks set-valued Names, and `compareApplyTerm`
      routes `==`/`!=`/`<=`/`<`/`>=`/`>` to `pySetEq`/`pySetSubset`/`pySetProperSubset`. keyboard-row →
      `['Alaska','Dad']`, close-strings → True/False. **[FIXED]**
      REMAINING: set/dict **iteration order** (intersection-of-two-arrays, find-the-difference) — the
      output list order differs from CPython's hash order; genuinely hard, deferred.
- [ ] **R8. mutation not threaded through recursion / called fn** (3: disconnect-path grid,
      is-graph-bipartite color, next-palindrome next_permutation) — NOT a targeted fix; needs
      mutable-reference semantics or threading through short-circuit conditions. Specifics:
      • is-graph-bipartite: the mutating recursive `dfs` sits inside `color[b]==0 and (not dfs(…))`
        — short-circuited; hoisting the call to thread `color` would evaluate `dfs` when it shouldn't
        (wrong + infinite recursion). • next-palindrome: `next_permutation(nums)` mutates its list
        *argument* (not a capture) and is called in an `if` test — needs mutable-ref *parameter*
        threading, which doesn't exist. • disconnect-path: recursive 2D-grid mutation, same class.
      All hit the known "mutating call in a condition/sub-expression position needs a hoist"
      limitation ([[value-rest-mutating-calls]]) — deferred; substantial feature, high risk.
- [ ] **R9. list mutation during iteration** (2: find-all-recipes `for i in q: q.append`,
      minimum-operations `enumerate` over mutated list) — Lean iterates a snapshot.
- [x] **R10. negative-int bitwise two's-complement** (2: convert-a-number-to-hexadecimal `>>`/`&15`,
      maximum-nesting-depth `&1`) — `pyBitAnd/Or/Xor` used `.toNat` → 0 on negatives. Now a 64-bit
      two's-complement model (`pyTwosComp`: unsigned rep → `Nat.land/lor/xor` → re-sign). `toHex(-1)
      = "ffffffff"`, `x&1` correct. Shifts were already floor-based (correct). **[FIXED]**
- [x] **R11. `bisect_left`/`right` didn't match CPython on unsorted input** (1: maximum-distance) —
      was `countP (y < x)` over the whole window (right only for sorted data). Reimplemented as CPython's
      actual binary search (`bisectSearch`, Array-backed), so it matches even on the out-of-spec
      unsorted test inputs the dataset uses. `maxDistance` 0→4 (= groundtruth). **[FIXED]**
- [x] **R12. int-as-truthiness in comprehension `if` filter** (1: counting-elements) — filter clauses
      lowered via `getCode … term` with no truthiness coercion. Fixed: `comprehensionFilterOver` now
      wraps each `if` clause with `truthyConditionTerm` (pyTruthy for a bare non-bool). `[1,1]` ✓.
- [ ] dict iteration order (1: find-a-good-subset) — hard, like set ordering.
- [ ] Float test-inputs into int-annotated params (3: number-of-sub-arrays-threshold, convex-polygon,
      find-k-closest) — dataset has floats in `int` slots; codegen is correct. Needs param widening. Skip.

**Agent 1 (tuple) / Agent 3 (PyAny) / Agent 5 (stuck+id) / Agent 6 (convert) — ROOT CAUSES:**
- **[HIGHEST LEVERAGE] untyped closure-captured binders** (Agent 5; ~5 direct + cascades into the 73× stuck
  AND ~34× Unknown-identifier buckets): closure-conversion emits captured outer vars as UNTYPED binders
  (`fun graph ↦`, `fun f ↦`) → container ops on them leave a metavar → `PyGetItem/PyIterable ?m` stuck →
  the helper fails → `Unknown identifier _fn_helper`/`Unknown constant fn` CASCADE (NOT missing fns!).
  sudoku-solver, valid-arrangement-of-pairs, get-equal-substrings-within-budget, construct-binary-tree-…-postorder,
  minimum-deletions-to-make-string-k-special. **Fix: annotate closure-captured binders with the inferred
  type** (extend `localAnnotations`/TypeInfer in `ClosureConvert.lean`). Do NOT add the `_fn_helper` names anywhere.
- **[HIGH] `set()`/set-literal slot ascribed `PyAny`** (Agent 3: 5 + Agent 1 number-of-distinct-islands; the
  37× `PyContains PyAny` bucket): `s = set()` → `let mut s : PyAny := pySetFromList []` → `x in s` needs
  `PyContains PyAny`, `s.add` wants `List α`. **Fix: TypeInfer infer set element type from `.add`/literal → `List T`.**
  check-if-n-and-its-double-exist, longest-nice-substring, longest-duplicate-substring.
- **[CLEAR] `sum(<bool generator>)` → `pySum (List Bool)` wants `PyHAdd Bool Bool Bool`** (Agent 2: 5 +
  Agent 1 count-unguarded). **Fix in `pySum` (Functional.lean): summing `List Bool` → `Int` (coerce Bool→0/1).**
- **[CLEAR] tuple literal used as list** (Agent 1: 4): `dirs=(0,1,0,-1,0)` then `dirs[k]`/iterate. **Fix:
  TypeInfer/codegen lower a homogeneous tuple literal to `List` when dynamically subscripted/iterated.**
- **[CLEAR] heap of tuples → `LinearOrder (ℤ×ℤ)`** (Agent 1: 3). **Fix: lexicographic `Ord`/`LinearOrder`
  for `Prod` in `Libraries/heapq`.**
- **[CLEAR CODEGEN BUG] `let mut X.field := …`** (Agent 4: flatten, construct-binary-tree; Agent 5 reverse-nodes)
  — attribute assignment `obj.field = v` emits invalid `let mut X.field :=`. **Fix `Assign.lean`: struct-update
  `obj := {obj with field := v}`.**
- **[CLEAR] subscript-through-attribute on a non-`self` local** (Agent 6: 4 Trie problems — `node.children[i]=X`):
  longest-word-with-all-prefixes, sum-of-prefix-scores-of-strings, search-suggestions-system, minimum-cost-to-convert-string-ii. One fix clears all 4.
- **[CLEAR] closure-as-value CAPTURING** (Agent 6: 4): `bisect_left(range, True, key=f)` where `f` captures.
  **Fix: `fun p ↦ new p caps` wrapper.** ODDITY: number-of-beautiful-integers = `@cache`-decorated recursive
  dfs mis-flagged as value-capture — unwrap `@cache`/`@lru_cache` before the check.
- **min/max `default=` kwarg** (Agent 5: 2 — minimum-falling-path-sum-ii, minimum-number-of-people-to-teach):
  extend `variadicFoldBuiltin` for `default=`.
- **Missing builtins** (Agent 5): `next(gen[, default])` → add `pyNext` (1&2-arg); `random.randint` (NONDETERMINISTIC
  — needs IO/seeded shim, flag).
- **numeric accumulator widening ℤ→Float** (Agent 3: min-cost-to-connect-all-points, maximum-price-to-fill-a-bag,
  probability-…): TypeInfer lattice widening when `ans=0` later takes a float.
- **inf typed ℚ splits from ℤ in tuples/containers/branches** (Agents 2,4): needs canonical inf typing across twins.
- **Counter/defaultdict mutation returns `List`** (Agent 3 number-of-unique-flavors): `cnt[k]+=1`/`cnt.pop()`
  lower to `pySetItem`/`pyPopRest` returning List, breaking the `PyDefaultDict` slot.
- **chained Option-unwrap** (Agent 4: height-of-special `root.left.right`) — recursive unwrap per attribute step.
- **generator-rebind** (Agent 6: 3 — max-area-of-island, couples-holding-hands, smallest-string-with-swaps):
  state-mutating helper in a GeneratorExp.
- Single-problem oddities: dict `.pop(k, default)` 2-arg (count-of-sub-multisets), `SortedList.bisect_left`
  method (find-servers), constant-tuple-index `t[i][0]` (advantage-shuffle), nested tuple comprehension target
  (stone-game-vi), Attribute tuple-assign targets `a.val,b.val=…` (recover-BST), loop-var retype String→ℤ
  (total-appeal-of-a-string), closure-rename miss in subscript index (the-earliest-moment).

### PROGRESS on fixes 1-8 (this session)
- [x] **#2 sum(bools)→Int** — `PySummand` outParam class (Bool→Int, num→self) in `Functional.lean`; pySum coerces. ✓ (3/6/4.0)
- [x] **#5 Ord/LinearOrder for Prod (heap of tuples)** — heapq switched `LinearOrder`→`Ord` (Lean's `Ord (α×β)` is lexicographic). ✓ heapmin→(1,2)
- [x] **#6 `obj.field = v` (non-self)** — `attrRecordUpdateDoElem` in `Assign.lean` (record-update+reassign, not invalid `let mut X.field`). ✓
- [x] **#7 subscript-through-attr on non-self** (`node.children[i]=v`) — same helper, wired into `nestedSubscriptSetDoElem?`. ✓
- [x] **#8 capturing closure-as-value → wrapper** — `rewriteHelperCalls` emits `fun p ↦ new p caps` (Lambda) for read-only capturing value-use; only threaded value-use still rejected. ✓
- [ ] **#1 annotate closure-captured binders** — untyped `fun graph ↦` → stuck; extend `localAnnotations`/TypeInfer for defaultdict/accumulate/Counter().values()/dict-comp.
- [ ] **#3 infer set() element type** (stop PyAny) — TypeInfer from `.add`/literal.
- [ ] **#4 tuple literal → List when dynamically indexed/iterated** — TypeInfer flow (homogeneous tuple + variable index).

### PROGRESS update 2
- [x] **#1 collection return types** — `Counter`/`defaultdict`/`accumulate` added to `builtinReturn` (Rules.lean) so captured binders get typed. ✓
- [x] **#3 set() element inference** — `applyMutation` `.add` now learns `.set` (not `.list`, which joined to PyAny). `s=set(); s.add(n)` → `List Int`. ✓
- [~] **#8 REVERTED** — capturing closure-as-value wrapper broke `pk_simulation.py` (untyped `fun state t ↦` odeint callback). Plumbing kept; needs typed wrapper params.
- [ ] **#4 tuple-literal-as-list** — DEFERRED (ripple on tuple-unpack/Prod.fst-snd; needs care).
- [x] **min/max `default=` kwarg** — `lowerMinMaxCall` emits `if pyLen==0 then default else …`. ✓
- [x] **`next(gen[, default])`** — eager-List head/headD in CallExpr. ✓

### PROGRESS update 3 (D11 kwargs + string methods)
- [x] **D11. `dict.pop(k, default)`** — a 2-arg pop is unambiguously a dict pop (list/set pop ≤1 arg).
      Added `pyDictPopValue`/`pyDictPopRest` (Pop.lean); `valueAndMutateMethod?`/`popCallParts?` now
      carry the arg array + rest-arg prefix so value form takes `(key, default)` and rest takes `key`.
      `x = d.pop(k, -1)` → `pyDictPopValue d k (-1)` + `d := pyDictPopRest d k`. ✓ (2/-1/[] verified)
- [x] **D8. missing string methods** — `title`/`swapcase`/`casefold`/`removeprefix`/`removesuffix`/
      `rjust`/`ljust`/`center` added (Strings.lean + Attributes.lean glue + Rules.lean `.str` return). ✓
      (all eval-verified against CPython, incl. `title`'s apostrophe word-split)
- [x] **D11. `dict.setdefault(k, default)`** — value+mutate like pop: value `pyGetD d k default`,
      rest `pyDictSetdefaultRest d k default` (inserts only when absent). Both `x = d.setdefault(...)`
      and bare-statement forms. TypeInfer already returns the dict-value type. ✓ (2/some 2/some 9)


### PROGRESS update 4 (D1 / D3)
- [x] class container field types + `partial` recursive methods (see D1 above). UnionFind verified
      vs CPython (True/False/apple/2).
- [x] polymorphic `float('inf')` sentinel (see D3 above). Verified vs CPython (6/2/3.0).
- [ ] **REMAINING GAP (found while testing): an EMPTY container class field** (`self.seen = {}`) has
      unknown element types, so `toAnnotation?` yields nothing and it still falls back to `Int`.
      Pre-existing (both the old `ofValue` path and the new one bottom out the same way). Needs the
      field type refined from *method-body usage* (`self.seen[w] = …`), not just the initialiser.
- Regression examples added: `example_scripts/typing/class_field_types.py`,
  `example_scripts/typing/numeric_sentinels.py` (both also run-verified against CPython).


### PROGRESS update 5 (D2 / D4)
- [x] **D4 CONFIRMED FIXED** — re-translated both named problems (height-checker `heightChecker`,
      find-the-number-of-good-pairs-i `numberOfPairs`); both compile clean. The corpus logs were
      stale (predate the `PySummand` fix).
- [x] **D2 largely fixed** — see above; 5 inference gaps + the library-registry fallthrough.
- [x] **D2 remainder DONE** — see PROGRESS update 6.
- Regression example added: `example_scripts/typing/captured_containers.py` (run-verified: 1/6).


### PROGRESS update 6 (D2 remainder — both named problems now clean)
- [x] **`defaultdict`/`Counter` captures** — rather than a new `PyType` variant (31 `.dict` match
      sites would each need updating), the distinction lives at the annotation boundary only: a
      `PyDefaultDict` *behaves* as a dict for inference, so `.dict` is kept and the stamp writes
      `defaultdict[k, v]`. `ofAnnotation` parses it back to `.dict`; the codegen annotation reader
      and `stampedTypeSyntax?` map it to `Libraries.collections.PyDefaultDict`. (`stampedTypeSyntax?`
      needed its own case — it round-trips through `PyType`, which would collapse it to `HashMap`.)
- [x] **tuple-typed locals ascribed** — `needsAscription` had no `.tuple` case, so a captured
      `t = []; t.append((i, j))` lifted untyped (sudoku-solver). Now true for a tuple of concrete
      scalars. Had to become `partial` (list recursion isn't structurally decreasing), matching
      `isKnown`.
- [x] **`i, j = t[k]` unpacked as a list** — the tuple-vs-list heuristic only accepted a Tuple
      literal or a Call RHS, so a Subscript RHS fell through to `pyListGetItem` on a `Prod`.
      TypeInfer now stamps `_tuple_unpack` when the RHS is tuple-typed, symmetric with
      `_list_unpack`, and both unpack sites honour it.
- Regression: `captured_containers.py` extended with a defaultdict/Counter/list-of-pairs capture;
  run-verified 1/6/13. PALC: 82 OK, 0 FAILED.
