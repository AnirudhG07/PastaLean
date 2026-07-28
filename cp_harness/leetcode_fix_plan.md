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

### Value+mutate on a SUBSCRIPT receiver (+2 so far)
`t = d[c].popleft()` / `mat[i][j] = g[k].pop()`: the value+mutate lowering only handled a Name
receiver. Added `popCallSubscriptParts?` (CallShared) for a `base[idx]` receiver on a mutable Name —
value = `valFn (pyGetItem base idx) args`, update = `base := pySetItem base idx (restFn (pyGetItem
base idx) restArgs)`. Assign now hoists a mutating RHS for a SUBSCRIPT target too (temp + update +
container rebuild). Fixes number-of-matching-subsequences, sort-the-matrix-diagonally.
STILL open (distinct mechanisms, not this fix): pop() as a call-ARG `dfs(g[f].pop())`
(reconstruct-itinerary), in a list-comp (find-anagram-mappings), or as a subscript INDEX
`ans[q[st].popleft()]=t` (time-taken-to-cross-the-door) — each needs a statement-level sub-expr hoist.

### Value+mutate hoist extended to subscript receivers + call-arg/index positions (+2 more)
`hoistMutatingCalls` (Desugar) already lifts `x.pop()` from eager sub-expression positions into a
preceding `_popv = x.pop()`. Extended `isValueMutateCall` to recognise a SUBSCRIPT receiver
(`g[f].pop()`), so `dfs(g[f].pop())` (call-arg) and `ans[q[st].popleft()] = t` (subscript index) now
hoist and compose with the subscript-receiver assign lowering. Fixes reconstruct-itinerary,
time-taken-to-cross-the-door. Hardened `hoistMutatingExpr` to NOT descend into conditional contexts
(comprehension/BoolOp/IfExp/lambda) — a mutation there is per-element/conditional and must not be
hoisted to once (find-anagram-mappings' list-comp pop correctly stays unsupported, valid-parentheses'
short-circuited `or` stays guarded). Total pop cluster this turn: +4 (num-matching-subseq,
sort-matrix-diagonally, reconstruct-itinerary, time-taken); still open: pop in a comprehension.

### Nullable Option: `optfield if X else None` double-`some` (+3 so far)
The linked-list/tree idiom `l1 = l1.next if l1 else None` compiled `some (l1.getD default).next`,
but `.next` is ALREADY `Option ListNode`, so `some` nested it to `Option (Option _)` → type mismatch
with `l1 : Option ListNode`. Fix: TypeInfer `markOptAttrs` marks an `X if c else None` IfExp whose
value branch types as `Option` with `_branch_opt`; codegen's `ifExpSyntax` then emits the branch bare
(no `some`) — a non-Option branch still gets `some` as before. Flips add-two-numbers,
closest-binary-search-tree-value, intersection-of-two-linked-lists; no regression (28/30 seed 5). Note:
the nullable cluster was already ~4/6 working from prior Option work; remaining fails are diverse
one-offs (PyGetItem-stuck, add-two-numbers-ii), not this pattern.

### defaultdict() empty (prerequisite, flips nothing alone)
Bare `defaultdict()` (no factory) now lowers to the empty dict `{}` instead of throwing. Correct in
isolation but the 3 corpus users each have a SECOND blocker (`defaultdict(lambda: [0]*m)` typing,
untyped-param→PyAny), so none flip on this alone.

### TRIED & REVERTED: nested-def return-type inference (net-negative)
Seeding nested-def return types into `sigs` + re-inferring the body env (stampFunction) DID fix
`node = dfs(root)` → `node.left` unwrap (binary-tree-coloring-game). But it REGRESSED add-one-row-to-tree
and count-univalue-subtrees: a void nested def that mutates an `Option` param (`def dfs(root,d): ...
root.left = TreeNode(...)`) got its `root` re-typed to `Option`, and the attribute-assign codegen then
emitted invalid `let root.left := …` + a Unit/Option return mismatch. Reverted. To land it safely, the
Option-param attribute-assignment codegen (`root.left = v` on an `Option` receiver) must first work
(unwrap-rebuild-rewrap), and void nested defs must not have their return coerced. Deferred.

### math `pow` star-shadow (+2, same class as the operator fix)
`from math import *` bound `pow` → `math.pow` (2-arg, float-only), shadowing the builtin `pow`. A
3-arg `pow(b, e, mod)` (modular exponentiation) then mis-resolved to the 2-arg library function →
"Function expected at". Fix (driver `_library_star_members`): exclude `pow` from EVERY library's star
set, so it always falls through to the builtin `pyPow` (which is variadic + modular). Flips
maximize-number-of-nice-divisors, count-k-subsequences-…; 2-arg `pow` users unaffected (builtin pow
handles floats). No regression (28/30 seed 5). Generalizes the earlier operator-star-shadow fix.

### sortedcontainers.SortedList (BIG — ~38/45 sampled pass)
Implemented `SortedList` as an ascending-sorted `List α` (same model as heapq), so subscript / `len` /
`in` / iteration / `index` / `count` / `pop` all come free from the list protocols; only order
maintenance + bisection are new runtime (`Libraries/sortedcontainers/SortedListDef.lean`:
pySortedList[Empty], pySortedAdd, pySortedRemove, pyBisectLeft/Right). Wiring: Mapping + Registry
(member map + behaviour), Attributes (`bisect_left/right/bisect` → runtime), a `sortedVars` codegen
flag (mirrors `setVars`) so `add`/`remove`/`discard` on a SortedList maintain order instead of set
semantics, and an arity-based empty-vs-iterable constructor in the special-call lowerer. 38 of 45
sampled SortedList problems now convert+compile (7 fails are unrelated: nested-return Option,
FenwickTree, anon-type). Runtime verified (PALC/Libraries/sortedcontainers/sortedlist_test.lean); no
regression (28/30 seed 5). Not yet: `.irange()` (rare), SortedDict/SortedSet.

### SortedList layering fix (follow-up)
Per feedback: library names must not live in codegen. Moved the SortedList instance-method map to
`Libraries/sortedcontainers/Mapping.lean` (`sortedListMethod?`) + a `Libraries.sortedListMethod?`
aggregator; CallExpr now only supplies the `isSortedVar` receiver gate (`sortedVarMethod?`) and calls
into Libraries. Also fixed a self-inflicted regression: bisect methods were in `pythonMethodMap?`
(hijacking `bisect.bisect_left` on a plain list) — now scoped to SortedList receivers only.

### AugAssign on a non-self attribute (correct, but coupled)
`node.count += val` (a local node/record, not `self`) emitted the invalid `node.count := …`. Fixed:
AugAssign now record-updates a non-self Attribute target (`node := { node with count := … }`), mirroring
the Assign path. Correct + regression-free (28/30), but flips 0 problems ALONE — every attr-augassign
user is a Trie/tree with a SECOND blocker (empty-dict `children` typing → `HashMap.ofList []` stuck).

### Landscape (post-SortedList): the coupled tail
Fresh random-60: 47 ok / 13 compile_fail (78% pass). No cluster of 3+ shares a cause. SortedList was
the last isolated lever. Remaining fails need WHOLE clusters fixed together (Trie: empty-container
inference + PyAny class-local + Option-field mutation + AugAssign, all at once), not single fixes.

### convert_fail sweep (one-by-one, +8 codegen-fixed)
Worked the convert_fail list directly (codegen errors, fast). Fixes (all regression-free, 28/30):
- **heapq mutators on subscript/attribute receivers**: `heappush(d[v], x)` / `heappop(row[i])` /
  `heappush(self.small, x)` now rebuild the container (LibraryMutators generalised past Name-only).
- **assignBackToReceiver attribute**: `self.h.append(v)` etc. now record-update the field.
- **slice-with-step assignment**: `nums[::2] = a` / `nums[1::2] = b` → new `pySliceSetStep` runtime
  (positive step); `sliceTargetParts?` returns the step instead of throwing.
Net: of 38 convert_fails, 4 fully flipped (distant-barcodes, sort-even-and-odd, split-array,
min-visited-cells) + 4 advanced convert→compile stage. Remaining convert_fails are hard/coupled:
pop-in-conditional (5), Unknown-constant-null closure bug (4), walrus-short-circuit (4), external
libs (re.sub/datetime/Queue), value+rest on attribute receiver (sliding-window-median).

### convert_fail sweep round 2 (+ statement-BoolOp, sort-on-subscript, bisect-module)
- **statement-BoolOp** (`u != v and uf.union(u,v)` as a bare statement → `if guard then effect`):
  added a `doElem` case to boolOpSyntax. Flips minimize-malware-spread ×2.
- **sort() on a subscript/attribute receiver** (`d[i].sort(reverse=True)`): routed through
  `mutatingMethodDoElem` instead of `getCode … ident`. Flips count-number-of-rectangles.
- **module-qualified library call via star-import** (`bisect.bisect_left(xs,x)` when only
  `from bisect import *`, so `bisect` was bound as the FUNCTION alias): driver now treats `X.attr`
  where X is a supported-library name as the MODULE. Corpus-wide (helps re/random/string/etc. too);
  advances depth-of-bst, odd-even-jump convert→compile. No regression (37/40 seed5, all pre-existing).
Total: 7 of 38 convert_fails fully flipped + 5 advanced to compile stage.

### TypeInfer engine investment (research-backed)
Researched Python's approach (mypy/pyrefly: bidirectional + infer-from-all-usages + Any fallback) and
bucketed 213/250 TI-related compile_fails. Biggest lever = container KEY inference (buckets 3+4+8 ≈ 66):
the engine learned element types from WRITES but not READS, and — critically — a dict captured by a
nested def (`d = defaultdict(list)` outer; `d[offset].append(v)` in `dfs`) never pinned its key because
`offset`'s type lives only in the INNER scope. Two changes:
- **learnFromReads** (Solve): pin a dict's key from subscript-READ positions (`d[k]`), the read side of
  "infer from all usages".
- **cross-scope capture-param inference**: thread each nested def's call-site param types
  (`nestedDefParamEnv`/`nestedParamHints`) into `applyCaptureMutations`, so a captured `d[param]` pins
  the outer `d`'s key from the inner `param` — written back to the receiver only (params never leak).
Flips binary-tree-vertical-order, reorder-routes, +3 defaultdict compile_fails; no regression (37/40).
Remaining in the cluster need more (node.val/attribute keys, PyDefaultDict-vs-HashMap ascription,
2-nested-def chains). NEXT engine targets: numeric-ℚ defaulting (bucket 1, ~36) and PyAny materialise
residual `.any` (bucket 2, ~29 — `toTypeSyntax? .any` currently returns none).

### TypeInfer round 2: numeric-`/` + PyAny materialisation
- **AugAssign true-division** (`x /= n` widens `x` to float even for ints): AugAssign used generic
  `arith` (int⊔int=int) while BinOp knew `/`→float. Now op-aware. Flips abbreviating-the-product-of-a-range.
  The rest of the numeric bucket (~36) is other sub-causes (List ℤ⊔List ℚ, ℝ transcendentals, numpy Float).
- **PyAny materialisation** (`toTypeSyntax? .any` → `PyAny`, so `list[any]` → `List PyAny`): completes the
  P3 total fallback for containers-of-any. Correct + NO regression (55/60 seed5, 2 pre-existing), but 0
  immediate flips — the PyAny compile_fail bucket is dominated by OVER-boxing (a value that should be
  `str`/`int` boxed to PyAny), which needs the char-vs-String / upstream element inference, not this.
Net TypeInfer investment (both rounds): cross-scope capture keys (~5) + AugAssign-div (+1), all
no-regression; PyAny materialisation is a correct foundation. Biggest remaining: char-vs-String
over-boxing (buckets 2+10 ≈ 36) and the numeric List-join/ℝ sub-causes.

### TypeInfer round 2b: char-over-boxing (ord→str)
Your point: char IS a str in our model (`PyIterable String String`, `elemType .str = .str` — correct).
The over-boxing was an UNANNOTATED param: `def insert(self, word)` with `for c in word: ord(c)` left
`word` unknown → `c` unknown → boxed to PyAny → `ord(PyAny)` fails. Fix: `for c in p` with `ord(c)`
(needs a 1-char str) pins `p : str` (containsOrdOf; narrowed to `ord` only so a nested
`for word in words: … ord(c)` doesn't mis-tag `words`). Confirmed `word:str`, `c:str`, no PyAny in
`insert`; no regression (46/50). Flips ~0 alone — the string problems have SECOND blockers
(Trie `children` = `List (Option Trie)`, bucket 11). Narrow (most str params are annotated).

### TypeInfer investment — honest summary
Research-backed, precise diagnosis (213/250), 5 correct no-regression changes: cross-scope capture
keys (+5), AugAssign-div (+1), PyAny materialisation (foundation), ord→str (foundation), learnFromReads
(foundation). Total measured flips ~6. The engine is now MORE correct + principled, but the compile_fail
tail is COUPLED — each failing problem stacks 2-4 blockers (Trie-fields + PyDefaultDict + numeric-join
+ closure-null), so single inference fixes seldom flip a whole problem. Next would need clearing a
whole coupled cluster (Trie: field-typing + PyAny-local + Option-mutation together), not more single fixes.

### FUNDAMENTAL LIMITATION: value semantics vs reference mutation (Trie / tree-node / DSU / graph-node)
The Trie cluster (~22) is NOT a typing gap — the typing is largely solved (`children : List (Option
Trie)`, `node : Option Trie`, `Trie.new`, Option-unwrap all generate correctly). Its real blocker is
architectural and shared with tree-node, DSU-parent, and graph-adjacency-node clusters:

Python builds these by REFERENCE mutation:
    node = self               # aliases the shared tree
    node.children[idx] = X()  # mutates the shared tree in place
    node = node.children[idx] # descend the reference

The transpiler uses VALUE semantics (classes are Lean `structure`s; `=` copies). So `node = self`
copies, every mutation lands on a throwaway copy, and the tree is never actually built → the code would
COMPILE but return WRONG answers (empty trie). Fixing the residual typing (`trie` boxed to PyAny, etc.)
is therefore pointless here — it makes compile-but-wrong code.

Correct handling needs one of: (a) mutable references (`ST`/`IO.Ref`) for class instances — a major
class-model redesign; (b) an explicit tree-threading source rewrite; (c) an index/dict-backed
representation. Each is a large project, not a cluster fix. RECOMMENDATION: do not invest in
Trie/DSU/graph-node compile fixes; they are semantic dead-ends under value semantics. Target the
typing/codegen clusters that have no semantic wall (numeric joins, tuple-vs-list, missing library ops).

### #3 Execution verification (compile ≠ correct)
- SortedList: CORRECT end-to-end (count-smaller-before [5,2,6,1]→[0,0,2,0], dups→[0,0,0], sorted→[0,1,2,3];
  runtime #eval-verified: sorted insert, bisect_left/right over dups, remove). The ~57 wins are real.
- pop-cluster (number-of-matching-subsequences, subscript-popleft): 8/8 correct.
- WARNING: `count-of-range-sum` COMPILES but is WRONG (0/8) — its `BinaryIndexedTree` mutates `self.c[x]`
  through a method; the value-semantics wall makes class-mutation-through-a-method compile-but-wrong.
  LESSON: a compile-win on a class that mutates self through a method (BIT/Trie/DSU/segment-tree) is
  likely a wrong-answer — verify execution, don't count the compile.
- NOTE: the evaluate harness only runs problems already `ok` in convert_summary.json AND that compile in
  the __main__-wrapped native harness — some convert-ok problems (classes) don't reach evaluate.

### #1 Numeric List-join — the inf-polymorphic-in-container tension
`f = [0] + [inf]*n` fails `PyHAdd (List ℤ) (List ℚ)`. Root cause: `inf = float('inf')` is typed `.any`
(the polymorphic `PyNonFinite` sentinel — deliberately int/float/ℚ per DP so an INTEGER DP using inf as
a sentinel still works). But `.any` forces any list holding inf to `List PyAny`, so `[0]`(List ℤ) ++
`[inf]*n`(List PyAny/ℚ) has no concat instance. Typing inf as float would fix float-DPs but break the
integer-DP sentinel use. This is a genuine coupled tension (not a clean fix) — needs canonical per-DP
inf typing that unifies the container element AND both twins, OR making list-concat element-coercing.
Simple `/=`→float (done) and non-inf numeric cases are handled; the inf-in-container cases remain.

### Session close-out: state of the tail
After extensive work (SortedList +57, convert_fail sweep, TypeInfer engine investment, char-over-boxing,
numeric `/=`), the remaining ~300 failures are genuinely hard/coupled: (a) value-semantics wall
(Trie/DSU/tree-node/BIT class mutation — compile-but-wrong, do not chase); (b) inf-polymorphic-in-
container numeric tension; (c) short-circuit hoist (pop/mutating-call in a conditional); (d) external
libs (re.sub/datetime/Queue/random); (e) feature-level (chain.from_iterable, cmp_to_key, SortedDict).
Clean single-fix wins are exhausted. Docs api_fix_checklist.md + array_backing_plan.md rewritten to
current state. All work verified no-regression; execution-verified where it matters (SortedList, pop).

### Class-method self-attr mutation → mutator (16 WRONG-ANSWER fixes, execution-verified)
Fenwick/segment-tree/BIT classes mutate `self.c[x] += v` in `update`/`modify`. The mutator detector
(`_method_mutates_self`, node_visitor.py) only recognised `self.X = v`, NOT `self.X[i] = v` (a Subscript
target), so these methods were classified non-mutating → `tree.update(...)` was `let _ := …` (result
discarded), the receiver never reassigned, mutations SILENTLY DROPPED → compiled but WRONG answers.
Fix: (1) `_mutates_self_attr` walks subscript chains to the self attribute; (2) `classSelfThreadingValue`
(ClassDef) now `let mut`-shadows mutated PARAMS too (`x += x & -x`), which the mutator path omitted
(else "`x` cannot be mutated" and the method failed to elaborate). ALL 16 convert-ok candidates now
80/80 (100%, 0 divergences) — count-of-range-sum 0/8→5/5, count-of-smaller-numbers, create-sorted-array,
peaks-in-array, … No regression (37/40 seed5). NOTE: does NOT help `node = self` aliasing (Trie) — that
is the deeper value-semantics wall. Edge case: a void mutator used as an EXPRESSION (`x=tree.update()`)
now throws "mutating method as expression" (was compile-but-wrong) — rare, acceptable.

### Class-mutator fix — REFINED (value-returning methods excluded) + honest impact
Refinement: a method that RETURNS a value other than self/None is NOT a pure void mutator
(`_method_returns_value`) — union-find `find` does path-compression `self.p[x]=…` AND returns the root
(`r = uf.find(i)`); treating it as a void mutator broke that (regressed 11 union-find, now recovered).
IMPACT (40 self-attr candidates, 26 evaluated): 20 CORRECT / 6 wrong (84.6%). The 20 correct include
the 16 BIT/segtree (were compile-but-wrong, now execution-verified) + void-`union` union-find. The 6
wrong are union-find where `union` RETURNS whether-merged AND mutates self — a value+mutate USER method
(needs both the return AND the mutation), which the mutator/plain-call binary can't model. This is the
pre-existing value+mutate-user-method wall (R8), NOT a regression (they were wrong before too). Net:
~16-20 wrong-answer fixes, execution-verified, no convert regression (37/40 seed5).

### Value+mutate USER methods — DONE (the R8 wall) — execution-verified
A method that BOTH mutates self AND returns a value (union-find `union` sets parents AND returns
whether-merged) is now a first-class "value mutator": lowered to return `(returnValue × Self)`, so the
caller binds both, reassigns the receiver, and uses the value. Pipeline:
- **node_visitor** `_method_is_value_mutator` = mutates-self-raw AND returns-a-value; emits
  `value_mutators` per class. **driver** folds base-class value_mutators + stamps `_is_value_mutator`
  on every stamped Call.
- **codegen** `classValueMutatorValue` (ClassDef): body built under `valueMutatorRef`, so each `return v`
  emits `return (v, self)` (Core/Assign returnSyntax); fall-through adds `return (default, self)` ONLY
  when the body doesn't already end in a `return` (else double-return "must be last element").
- **call sites**: statement `uf.union(a,b)` → `uf := (C.union uf a b).2` (drop value); expression
  position (`x = uf.union(a,b)`, `if uf.union(a,b):`, `ans += uf.union(a,b)`) → `userValueMutatorRhsLowering?`
  gives `(call.1, uf := call.2)`, and a **Desugar hoist** (`isValueMutateCall` now recognises the stamp;
  whole-expr calls hoist everywhere except direct-lower `Expr`/`Assign`/`Return` value positions) pulls
  the call out of If/Assert-test and nested positions into a temp first.
- Recursive value mutators work (`find` path-compression `self.p[x] = self.find(self.p[x])`: threaded self
  through the recursion + nested-call hoist in the self-attr assign).
Verified: union_find.py regression test (`if uf.union`, `count -= 1` AND `merges += uf.union`) runs
2/4 == Python; recursive-find DSU runs 3 == Python. No golden drift (pop_methods, mutating_methods, nn
showcase all IDENTICAL). Unlocks ~6 union-find problems whose `union` returns whether-merged. Remaining
union-find gaps are `enumerate`+nested-tuple-unpack (`for i,(x,y) in enumerate(..)`) codegen slowness,
unrelated to this feature.

### Sweep batch (2026-07-28): 3 robust compile_fail fixes
Categorized the 280 compile_fails (aggregated from per-problem sol_0.status/.log; ~28 are stale
py2lean-build-race "object file … does not exist", not real). Three robust wins landed + verified:

1. **Memoized DP mutated params** (`FuncDef.memoizedRunCommand?`): the `@cache`/`@lru_cache` run-twin
   bound params as immutable binders, so a body that reassigns a param (`k += …`) failed with "`k`
   cannot be mutated". Added the same `let mut p := p` prelude the non-memoized path uses, inside the
   `| none =>` cache-miss branch. Fixes number-of-ways-to-divide-a-long-corridor; unblocks the mutation
   layer for ALL memoized DPs (many then hit the deeper ℚ/Float return-type cluster — separate issue).
2. **`str.startswith`/`endswith` with start/end** (`PyAPI/Strings.lean`): added `(start stop : Option
   Int := none)` optParams; `s.startswith(p, i)` slices `s[i:]` first (Lean's core `Coe α (Option α)`
   lifts the `i` arg). Fixes find-and-replace-in-string. 2-arg calls unchanged (identical branch).
3. **User functions shadowing Lean globals** (`driver.rename_reserved_shadows` + node_visitor guard):
   a user `def max(...)` lands in root alongside core `max` → "ambiguous identifier `max`: [Max.max,
   max]". Rename such top-level defs (and their references, scope-aware — skips nested scopes that
   rebind the name) to `<name>'usr` (the `'` can't clash with a Python name). RESERVED = max/min/insert/
   id/pred/succ. Also guarded node_visitor's `min/max(a,b)→min/max([a,b])` iterable-normalization to skip
   user-shadowed names (else the renamed user fn got called with one list arg). Fixes insert-interval,
   maximum-sum-of-subsequence-… (max part; that one then hits a separate SegmentTree.build bug).

Regression: str_attributes/decorators goldens IDENTICAL; builtin max/min still normalizes to pyMax when
unshadowed. New regression tests: example_scripts/general/name_shadows_and_slices.py,
example_scripts/commands/memo_mutated_param.py (both execution-verified == CPython).

### Short-circuit value+mutate calls (`cond and uf.union(...)`) — DONE
The value+mutate feature downgraded 5 union-find solutions from compile-ok(wrong) to compile-fail:
`cond and uf.union(a,b)` sits in a BoolOp (a conditional context the plain hoist skips), leaving the
`(Bool × UnionFind)` tuple in a truthy position → "PyTruthy (Bool × UnionFind)". New Desugar pass
`hoistShortCircuitMutator` (runs before hoistMutatingCalls) rewrites an `If`/`Assert` whose test is a
top-level `and`/`or` whose LAST operand is a value+mutate call and earlier operands are pure:
`if A and M: BODY` → `sc'=False; if A: sc'=M; if sc': BODY` (`or` → seed True, guard `not A`). The
`sc'=M` assign lowers via the existing value+rest path (bind bool, reassign receiver) — so the mutation
runs, and its receiver is threaded, ONLY on the branch Python evaluates. Also covers `A and xs.pop()`.
Fixes similar-string-groups; execution-verified (short-circuit test: mutation runs only when gate open).
Regression test extended: example_scripts/commands/union_find.py `count_gated`. Mutator NOT last in the
chain is left untouched (rare). number-of-provinces also now OK.

### Dead-end noted: `Counter`/`defaultdict` as a TYPE ANNOTATION
`def dfs(cnt: Counter)` → "Unknown identifier `Counter`" (annotation falls through to `.cls "Counter"`).
Tried mapping `Counter`→`.dict _ int` in TypeInfer/Annotation baseTypes+containerOf, but: (a) the key
type stays unknown → "match pattern variable metavariable" (needs interprocedural key inference, P2);
(b) worse, `Counter(xs)` VALUES emit as `Libraries.collections.PyDefaultDict`, while `.dict`→`Std.HashMap`,
so a `Counter[str]` param (`Std.HashMap String Int`) mismatches the `PyDefaultDict` argument. The lattice
can't distinguish Counter/defaultdict dicts from plain dicts, so this needs the TypeInfer investment
(a runtime-type-carrying dict variant), NOT a sweep fix. REVERTED. `Counter(xs)` as a value still works.

### Batch tally (this session): 7 problems closed, execution-verified
number-of-ways-to-divide-a-long-corridor, find-and-replace-in-string, insert-interval,
similar-string-groups, number-of-provinces, capitalize-the-title, brace-expansion-ii — all convert+compile
OK together. Plus the value+mutate union-find feature (number-of-provinces + others). Remaining
compile_fails are dominated by the hard numeric-ℚ/Float + type-inference clusters (Application type
mismatch, PyAny synth, nullable Option, tuple-vs-list) — the TypeInfer plan's territory.
