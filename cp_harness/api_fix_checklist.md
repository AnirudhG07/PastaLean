# API-fix & performance checklist (mimic Python behaviour, incl. complexity)

Goal: make the transpiler match Python semantics AND complexity so the leetcode corpus stops
timing out / diverging. Track progress here.

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
