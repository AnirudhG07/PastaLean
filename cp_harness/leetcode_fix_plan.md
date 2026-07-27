# LeetCode fix plan — ease-ordered sweep (rewritten 2026-07-27)

Baseline (overnight_leetcode.log): **2216 ok / 314 compile_fail / 59 convert_fail** of 2589.
Target: ~100 more today. Strategy: sweep **easiest → hardest**, not most-quantity-first.
(Previous plan archived at `leetcode_fix_plan_archive_prev.md`.)

Root causes below are from a 4-agent parallel analysis of all 373 failures. Ease is
trivial / easy / medium / hard. Counts are problems the fix unblocks (some are the *next* error, so
staged fixes chain). **Skip TIER 3 (each is a whole feature/library, not a fix).**

---

## TIER 0 — trivial/easy, high confidence (do first)

- [x] **`operator` library** — EASY, **13**. `from operator import *` fell through to Lean's `Bool`
  `xor`. Added `Libraries/operator/{OperatorDef,Mapping}.lean` (xor/or_/and_ → `pyBit*`; add/sub/mul/
  mod/floordiv wrappers) + Registry. **DONE — all 13 compile.**
- [ ] **`map` / `nlargest` / `nsmallest` return-shape** — EASY, **3+**. Unpack `x,y = nlargest(2,xs)` /
  `a,b = map(int, s.split())` is stamped tuple because these have no `Behaviour`. Add entries to
  `Libraries/Behaviour.lean` (`nlargest`/`nsmallest` → `listOf 0`; `map` → list of elem). Unblocks
  largest-number-at-least-twice-of-others, complex-number-multiplication, number-of-days-between-two-dates.
- [ ] **mutating-call unpack hardcodes `Prod`** — TRIVIAL, **1** (+ shares plumbing with TIER 1). One
  line in `Core/Assign.lean` (~L413): the value+rest unpack path passes `unpackAccessTerm true`; use the
  target's `_list_unpack`/`_tuple_unpack` stamp like the normal path. Unblocks find-k-pairs-with-smallest-sums.
- [ ] **`defaultdict()` empty / `defaultdict(lambda: <literal>)`** — EASY, **3-4**. Empty → plain dict
  (trivial); `lambda: <literal>` → default value (easy: inf / 1 / [0]*m). `Calls/SpecialCalls/Collections.lean`.
  Unblocks evaluate-division, construct-string-with-minimum-cost, rank-teams-by-votes (`defaultdict(TreeNode)` is medium, skip).

## TIER 1 — medium effort, ONE root cause, HIGHEST yield

- [ ] **tuple-vs-list unpack (`List ℤ` gets `Prod.fst/snd`)** — MEDIUM, **~28** (biggest lever). A value
  Lean typed `List ℤ` is projected with `Prod.fst/snd` because `enumerate`/nested-`for` desugar
  (`Desugar.flattenForTargets`) eager-stamps `_tuple_unpack` and inference never clears it. **Robust fix:**
  codegen must never emit `Prod` access on a value whose inferred type is a `List`, AND
  `stampUnpackShape` (`TypeInfer/Solve.lean` ~L1085) must *replace* a stale `_tuple_unpack` with
  `_list_unpack` (thread the loop-target element type into the For-body env). One decision point in
  `Core/Assign.lean` `isTuple` (~L437). Covers the whole 30-problem "ARG List ℤ" cluster (2 one-offs:
  `*args`-splat, float-key bisect).
- [ ] **Trie / segment-tree None-fields (13)** — pair two fixes, ship together:
  (a) EASY — None-default class field → `Option C` / `List (Option C)` not `Unit`
  (`ClassDef.lean classStructFieldSyntax` else-branch); (b) MEDIUM — a mutated class-local widened to
  `PyAny` must retain `.cls C` (`TypeInfer/Solve.lean` local widening). Unblocks the Trie cluster
  (add-bold-tag-in-string, bold-words-in-string, concatenated-words, word-break-ii, word-abbreviation,
  sum-of-prefix-scores-of-strings, longest-common-suffix-queries, word-search-ii, …) + falling-squares,
  amount-of-new-area-painted-each-day.
- [ ] **closure-threading null bug + non-lvalue arg (7)** — MEDIUM, `Transform/ClosureConvert.lean` (our
  own recent code): (a) a self-recursive *threaded* helper tuple-unpacking its result leaks `Json.null`
  → "Unknown constant null" (binary-tree-longest-consecutive-sequence-ii, brace-expansion,
  count-the-number-of-complete-components, difference-between-maximum-and-minimum-price-sum,
  sum-of-remoteness-of-all-cells); (b) a threaded arg that isn't a Name/Subscript (`dfs(deque(s))`,
  `dfs(src,tgt,set())`) must hoist to a temp before rebinding (basic-calculator-iii, escape-a-large-maze).

## TIER 2 — medium

- [ ] **comprehension/generator target captured as free var in nested defs (8)** —
  `ClosureConvert.lean` free-var analysis must subtract comprehension/`for`-gen targets (spurious
  `fun i` param). best-meeting-point, build-a-matrix-with-conditions, maximum-prime-difference,
  most-frequent-prime, non-decreasing-array, prime-in-diagonal, shopping-offers, reorder-routes-….
- [ ] **type-changing reassignment `s = list(s)` shadow (5)** — `Core/Assign.lean`: rebinding an
  existing `let mut` with a new type → rename. shifting-letters, movement-of-robots, open-the-lock,
  replace-all-digits-with-characters, replace-all-s-to-avoid-consecutive-repeating-characters.
- [ ] **value-and-mutate hoist family (up to 12)** — MEDIUM-HARD, one hoist-to-temp mechanism
  (`CallShared.lean`/`Assign.lean`): `pop()`/`heappop()`/`popleft()`/`setdefault()` used in a
  sub-expression. find-anagram-mappings, reconstruct-itinerary, valid-parentheses, tag-validator,
  sort-the-matrix-diagonally, parsing-a-boolean-expression, lexicographically-minimum-string-…,
  number-of-matching-subsequences, time-taken-to-cross-the-door, + 3 heapq positional.
- [ ] **binder collides with `math` constant `e`/`pi` (2)** — extend `driver.py`
  `_strip_library_annotation_from_binders` to comprehension/lambda targets. car-pooling, meeting-rooms-ii.
- [ ] **user `def max`/`min`/`insert` clashes open'd Lean name (3)** — rename colliding user defs.
  stone-game-v, minimum-degree-of-a-connected-trio-in-a-graph, insert-interval.
- [ ] **`nlargest(..., key=…)` kwarg (2)**, **mutating method on subscript receiver `d[y].sort()` (4)**,
  **slice-step `s[a:b:c]=` (2)**, **for-target star-unpack (1)**, **itertools.chain / plain bisect module (3)**.

## TIER 3 — HARD, SKIP (whole features)

- `sortedcontainers.SortedList` (~14 across convert+compile) — full order-maintaining structure.
- WALRUS in BoolOp / while-test (4) — can't hoist without changing short-circuit/re-eval.
- DSU `union()` used as value / statement-BoolOp side-effect (4) — value-semantics threading of a
  user method that mutates `self` and returns.
- Class-based segment trees, attribute-of-subscript lvalue (`self.tr[u].l`) (~4).
- Single awkward library members: `datetime.date` arithmetic, `functools.cmp_to_key`, `re.sub`,
  `Queue.put`, `itertools.count` unbounded, `random.randint`, `setattr` monkeypatch, interactive judges.

---

## Sweep tally (today) — running total from 2216

- **operator library**: **+13** (verified — all 13 xor/or_/and_ problems compile). Also fixed a
  self-inflicted regression: `from operator import *` is in EVERY preamble, so operator's star-members
  are restricted (driver) to only the mapped names, leaving `abs`/`pow`/… to their builtins.
- **tuple-vs-list unpack (`_list_unpack` wins)**: **+25 of 30** in the List ℤ cluster. Root cause was
  codegen preferring the desugar's stale `_tuple_unpack` over inference's `_list_unpack`; fixed at all
  4 `isTuple` sites (`Core/Assign.lean` ×3 + `UseCases/FuncDef.lean` pure-let path) so `_list_unpack`
  wins, + `map`/`nlargest`/`nsmallest` return-shape `Behaviour`s + the mutating-unpack `Assign.lean`
  hardcoded-`Prod`. No regressions (unpack-heavy smoke set clean).

- **non-lvalue threaded-arg**: **+1+** (basic-calculator-iii; escape-a-large-maze converts) —
  `threadedTargetsFor` discards a threaded param passed a fresh value (`dfs(deque(s))`) into `_`.
- **comprehension-var capture**: **+7 of 8** — a nested def's `[v for v in …]` was capturing the
  comprehension target `v` as a spurious untyped param; `comprehensionBoundNames` (ClosureConvert)
  excludes comprehension/lambda targets from the free-var set.
- **defaultdict(lambda:…)**: converts (`PyDefaultDict.empty <expr>`) but 2 have downstream type gaps
  (key-type metavar, numeric list-add) — not clean flips yet.
- **Trie/segment-tree None-field**: class field `None`/`[None]*k` now types `Option C`/`List (Option C)`
  (ClassDef) — correct prerequisite, but the cluster's real blocker is the general `none : Option ?m`
  nullable-inference gap (None-default PARAMS, constructor `None` literals) — MEDIUM, deferred.

**Fail-set re-measure (definitive, all Lean fixes): 49 of 373 → ok** + math-const +2 (Python) ⇒ **~2216 → ~2267** (+51).
Remaining easy-ish: type-changing-reassignment shadow (5), user-def name clash max/min/insert (3),
math-const binder e/pi (2). Medium: `none : Option ?m` nullable inference (biggest remaining, ~15+).
**TODO (user request): `isinstance()` support — commonly used; add later.**

### Prerequisites landed (not clean flips yet, but correct + regression-free)
- **None/list-of-None class fields → `Option C` / `List (Option C)`** (`classFieldSigs` + `ClassDef`):
  a Trie's `children = [None]*26` / a node's `self.left = None` now type correctly instead of
  `List Unit`/`Unit`. Advances the whole Trie/segment-tree cluster to its NEXT error (loop-var
  `c : PyAny`, `node.cnt` field-mutation on an `Option`, class-local `Trie → PyAny`) — those (Agent B
  #2 + follow-ons) are the remaining medium work for that cluster.

### Next targets (medium, ranked)
1. `none : Option ?m` nullable inference — None-default PARAMS (`def f(node=None)`) + Trie class-local
   `PyAny` + `node.attr` mutation on an `Option` — the biggest remaining bucket (~15+, several coupled).
2. type-changing reassignment `s = list(s)` shadow (5) — needs a rename pass.
3. user `def max/min/insert` clash (3); value-and-mutate sub-expression hoist (~12, one mechanism).

### Numeric tuple-unpack widening (+3)
- `left, right = (0, 1e8)` then `left = mid : ℚ` — the int-seeded unpack element is widened by a later
  reassignment. `stampNumericTupleElemTys` (TypeInfer) ascribes each numeric unpack element its
  ENV-joined `_ty`, and `tupleElementAssignDoElem` (Assign) coerces (`↑`) the projection so the ℚ
  ascription doesn't back-unify the `ℤ × ℚ` tuple. minimize-max-distance-to-gas-station,
  maximum-average-subarray-ii, pour-water-…. (Plain-assign / memoized-dfs numeric widening remains.)

### Best-effort: per-statement degradation (user request)
`pyUnsupported` degradation is now **per-statement at every nesting level** (function body + each
loop/branch body via a shared `getStmtDoElem`), not per-whole-function. A single bad line (e.g.
`d[y].sort()` inside a `for`) degrades to `pyUnsupported "degraded <NodeType>: <error>"` — clearer,
naming the failing node + error — while the REST of the function compiles. Plumbed a `best_effort`
flag through the translate task (`bestEffortRef`); strict mode (default `--strict`) re-raises unchanged.
NOTE: structural errors thrown DURING closure-conversion (before body lowering, e.g. the "Unknown
constant null" threaded-tuple-unpack bug) still collapse the whole function — those need the underlying
bug fixed, not degradation.

### Type-changing reassignment SSA-rename (+4 of 5)
`s = list(s)` (str→List) on a mutated PARAM: the param's mutable shadow (`let mut s := s`) pins `s` to
`String`, so the retype can neither re-`let mut s` (Lean forbids shadowing a mut var) nor reassign
(types differ). Fix = SSA-rename: a type-changing rebind of an existing `let mut` binds a fresh
`let mut s'rbN := rhs` and renames every later `s` reference (rename map in codegen State, applied in
`nameSyntax`, saved/restored per block). FuncDef now `setMutVar`s the param shadow so codegen sees it
as a real mut var and takes the rename path. Fixes shifting-letters, movement-of-robots,
replace-all-digits-with-characters, replace-all-s-…; open-the-lock hits a separate `PyIntCast PyAny`.

### `@[py_convert "name"]` extension point (design deliverable)
A user can now support a new Python conversion `a = name(s)` by tagging ONE Lean function
`@[py_convert "name"] def pyMyConv {α} [MyConvCast α] (x : α) : T` — no `pythonBuiltinMap?` edit. The
name pins the target type (Lean can't infer it backwards at an untyped `let mut`); the tagged function
stays open on its source via its own typeclass, so a new source is just another instance. Registry
(`pyConvertExt`) is consulted as a fallback in `builtinMappedName?` after the built-in tables, so it
can't shadow `int`/`str`/`list`; composes with the SSA-rename so the retyped assignment stitches.
Regression test: PALC/PyAPI/TestPyConvert.lean.
