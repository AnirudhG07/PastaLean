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

### Next-2-easiest batch: memo type-changing param + dict.pop(key)
1. **Memoized-DP param reassigned same-type** (`sort-integers-by-the-power-value`): completes the
   earlier memo mut-shadow fix — the shadow loop in `memoizedRunCommand?` emitted `let mut p := p` but
   never `addVar`/`setMutVar`'d `p`, so a later plain assign (`x = 3*x+1`) lowered to a FRESH `let mut x`
   → "mutable variable `x` cannot be shadowed". Added the two registrations (mirrors the non-memoized
   path). → sort-integers OK.
2. **`dict.pop(key)` misrouted to list pop** (`find-the-median-of-the-uniqueness-array`): 1-arg
   `d.pop(k)` shares its name with `list.pop(i)`, and `valueAndMutateMethod?` defaulted argc≤1 to LIST
   pop (`pyPopRest` → returns a List → type error). Added a `dictVars` codegen registry (mirrors
   `setVars`/`sortedVars`, populated from `{…}`/dict-comp/`dict()`/`defaultdict()`/`Counter()` via
   `jsonIsDictExpr`) and routed `d.pop(k)` on a dict receiver to a new polymorphic `PyDictKeyPop`
   protocol (`pyDictKeyPopValue`/`pyDictKeyPopRest`, instances for `Std.HashMap` AND `PyDefaultDict`) —
   one call site handles plain dicts and Counters/defaultdicts. → find-the-median OK.
Regression test: example_scripts/commands/dict_pop_and_memo.py (dict.pop on plain dict + Counter, memo
collatz reassigning its param) — execution-verified 50/7/8 == CPython. No golden drift (pop_methods,
mutating_methods identical); 80/80 codegen sweep clean.

### Fresh re-measure (2026-07-29, random-70 seed 13): 64 ok / 6 compile_fail (91%)
Up from the 85.6% overnight baseline — the accumulated sweep fixes moved the needle. Categorized ALL 6
fresh fails; every one is coupled/TypeInfer-bound, NOT a mechanical win:
- **name-reuse type conflict** (2: detect-cycles-in-2d-grid, minimum-cost-to-convert-string-i): Python
  reuses `x` as `str` in one loop and `int` in another; TypeInfer joins the conflicting uses to `PyAny`
  → `grid[PyAny]` / `str×str×int` unpack mismatch. Needs per-scope/SSA inference (not just codegen SSA).
- **`key=` callback param inference** (1: subsequence-with-the-minimum-score): `bisect_left(range(n+1),
  True, key=check)` — `check`'s param is `PyAny` because the range's `int` element type isn't propagated
  into the callback. Same class as the `nlargest(key=…)` item. Medium TypeInfer (call-graph) work.
- **nullable tree mutation** (1: increasing-order-search-tree): `root.left = None` + `prev.right = root`
  threaded through a nested def → value-semantics wall + `@none : Option ?m` + closure-threading, all at
  once. Hard.
- **inf-in-container numeric** (1: egg-drop-…): `PyHAdd (List ℤ) (List ℚ)` — the documented inf-poly
  tension. **random lib** (1: sort-an-array `randint`) — only 2 corpus users, not worth a shim.
CONCLUSION (confirms the close-out above): clean single-fix wins are exhausted. The next real levers are
MEDIUM TypeInfer investments — (a) per-scope typing for name-reuse, (b) `key=`/callback param inference,
(c) tuple-element inference for list-of-tuples — each spanning the inference engine, not a sweep fix.

### Medium TypeInfer lever DONE: `key=` callback param inference
The `key=<named def>` case (`bisect_left(range(n), True, key=check)` / `sorted(xs, key=f)` /
`min(xs, key=f)`): the callback is never called by name, so `nestedParamHints` (positional-call hints)
left its param `unknown` → boxed to `PyAny` → `check`'s body (`k + x`) went `ℤ × PyAny`, unpack failed.
`stampKeyLambdas` already handled `key=lambda` inline; extended the same collection-finding
(`keyCallbackColl?`, covers sorted/min/max/bisect_*/nlargest/nsmallest/.sort) to NAMED defs:
`keyCallbackElemTypes` collects the element type at every `key=<name>` site, `keyCallbackHints` hints the
def's FIRST param with the joined element type, merged (join, not override) into `stampStmt`'s nested-def
hints. Fixes subsequence-with-the-minimum-score. Regression: random-70 seed13 64→65 (only this flipped,
0 new fails); 80/80 example codegen; execution-verified via example_scripts/commands/key_callback_infer.py
(named annotated + named unannotated + lambda control, all == CPython).

### Codegen bug DONE: nested tuple-unpack of a threaded call in a `do` block leaked `null` (+4)
The "Unknown constant `null`" convert_fail (our own ClosureConvert code, TIER 1). A nested def that
mutates a capture (state-THREADED) AND returns a tuple, tuple-unpacked (`a, b = dfs(i)`), rewrites to
`((a, b), vis) = dfs'(i, vis)` — a NESTED tuple target. In a PURE `let`-chain (top-level, no loop) it
lowered fine; but inside a `do` block (e.g. a `for` loop), the nested `tupleElementAssignDoElem`
produces a nested `mkNullNode`, and `appendDoElems` flattened only ONE level, so the inner wrapper
leaked into the do-sequence and elaborated as a stray `null`. Root fix (robust, any depth):
`appendDoElems` (Core/Utils.lean) now flattens `nullKind` RECURSIVELY (`getArgs.foldl appendDoElems`).
Flips brace-expansion, count-the-number-of-complete-components, difference-between-maximum-and-minimum-
price-sum, sum-of-remoteness-of-all-cells (binary-tree-longest-consecutive-sequence-ii progresses to a
separate `List ℤ × ℤ` threaded-tree tuple mismatch). Regression: 90/90 example codegen, goldens
(pop_methods/mutating_methods) IDENTICAL (existing cases had one nesting level → unchanged);
execution-verified (threaded tuple-unpack in a loop == CPython). Regression test:
example_scripts/commands/threaded_tuple_unpack.py.

### API wrong-answer fixes (from eval_divergences.json) — 3 systematic runtime bugs
Above 90% convert now; turned to the eval divergences (Lean compiles but WRONG output). Three
systematic API bugs fixed (each affects any problem using that op), all regression-free (PALC runtime
#guards pass; random-40 eval 91.8%, no NEW divergences — the 1 wrong-output `last-day-…` pre-existed,
3 others are DP timeouts):
1. **Integer bitwise was fixed 64-bit two's-complement** (`PyAPI/Operators.lean` `pyTwosComp`,
   `pyBitWidth := 64`): a non-negative `&`/`|`/`^` result ≥ 2^63 got RE-SIGNED to negative
   (`reduce(or_, nums)` → -1 instead of 2^64-1) and anything wider than 64 bits truncated. Python ints
   are arbitrary-precision. Fix: DYNAMIC width = `(max magnitude).log2 + 2` (strictly > either operand),
   so a non-negative result never sets the sign bit and nothing truncates; negatives still round-trip
   (`-1 & 5 = 5`). Fixes maximum-xor-after-operations, maximum-xor-product (10/10 each).
2. **`str.split()`/`strip()` whitespace set** (`Strings.lean` `isPyWhitespace`): only `' \t\n\r'`.
   Added `\v \f` + Unicode NEL/NBSP (`\x0b\x0c\x1c-\x1f\x85\xa0  `) so `"a\xa0b".split()`
   drops the non-breaking space like CPython. Fixes reverse-words-in-a-string.
3. **Format-spec radix `{:02x}`/`{:o}`/`{:b}`** (`Core.lean` `pyFmtApply` + new `pyIntToRadix`):
   `str.format` pre-renders args to DECIMAL, so `'{:02x}'.format(153)` gave `"153"` not `"99"`. Now
   `pyFmtApply` converts an integer arg to the type char's radix (covers BOTH `str.format` and
   f-strings, which both route through it). Fixes similar-rgb-color, convert-a-number-to-hexadecimal.
Regression tests: PALC/PyAPI/TestOperators.lean (new, bitwise), TestStrings.lean (+split/format guards).
Also corrected a stale PALC lattice #guard (`emitted (.list .any)` → `List PyAny`, from the committed
PyAny-materialization). Deferred (fiddly, pathological inputs): large-float `.2f` UInt64 overflow
(apply-discount); CPython set-hash iteration ORDER (intersection/find-the-difference — inherent to the
list-backed set model, not a clean fix).

### API wrong-answer fixes, batch 2 — 4 systematic semantic bugs (+~10 problems)
More eval-divergence fixes (execution-verified 100% on the affected problems; 95/95 codegen sweep,
pop/mutator goldens identical). NOTE: `evaluate` reads the on-disk `sol_0.lean`, so a codegen fix needs
a RE-CONVERT before the eval reflects it (a stale-`.lean` eval misled me mid-session).
1. **`for x in q` where the body GROWS `q`** (BFS/topological idiom, `q.append(...)`): a Lean `for`
   snapshots the iterable, so appended items were never visited → BFS processed only the seed queue.
   `ControlFlow`: when the body grows the iterated Name (`bodyGrowsListVar`), lower to an index `while`
   re-reading `pyLen q`, advancing at the TOP so `continue` re-checks the grown length. Fixes
   course-schedule, bus-routes, detonate-the-maximum-bombs, minimum-genetic-mutation, find-all-recipes.
2. **Nested `and`/`or` with a non-bool operand lost its condition context in `'rn`** (`Basic.boolOpSyntax`):
   `a or (b and n)` in a condition — the outer `or`'s operand was lowered with `withPropCondition opProp`,
   but `opProp = propCond && exact` is FALSE in approx mode, so the nested `and` fell to the VALUE form
   (`if pyTruthy b then n_int else b`) and the `Int` operand was mis-coerced. Fix: lower operands under
   `withTruthinessContext true` so nested BoolOps stay in the Bool/Prop connective form. Fixes
   day-of-the-year (`y%4==0 and y%100`).
3. **`sum(<bools>)` typed as `bool`** (`Libraries.Behaviour` `sum`): Python `sum([True,False,True])=2`
   (int). `sum` returned the element type; a `sum(c in vowels for …)` counting idiom typed the chained
   temp `Bool`, corrupting the count. New `sumReturn` widens `bool`→`int` (`min`/`max` keep bool). Fixes
   maximum-number-of-vowels.
4. **`for row in C: <mutate row in place>` lost the mutation** (value-semantics element mutation):
   the loop var is a value copy, so `row[i]=v` / `row.sort()` never reached `C`. `ControlFlow`:
   `forElemWriteback?` detects it (target mutated in place, no break/continue, C a Name) and lowers to an
   index `while` that WRITES the mutated element back (`C := pySetItem C idx row`); `jsonMutatesName`
   (FuncDef) now recognises the pattern so `C` becomes a `let mut`. Fixes flipping-an-image,
   sum-in-a-matrix, delete-greatest-value-in-each-row.
Regression test: example_scripts/commands/api_iteration_semantics.py (all 4 patterns, == CPython).
STILL DEFERRED: CPython set-hash iteration ORDER (intersection/find-the-difference/powerful-integers —
inherent to list-backed sets); large-float `.2f` UInt64 overflow (apply-discount); assorted per-problem
logic bugs (count-number-of-teams, path-with-maximum-gold, least-operators, …).

### API batch 3 — sum-bool auto-fixed ~10 more; + enumerate-container-mutation
Re-evaluating the ~24 remaining divergent "logic bugs" (after re-convert!) showed the systematic fixes —
especially `sum(<bool>)`→int — had ALREADY auto-fixed ~10 of them: maximum-height-by-stacking-cuboids,
count-number-of-teams, maximum-rows-covered-by-columns, last-day-where-you-can-still-cross,
maximum-star-sum-of-a-graph, sum-of-digit-differences-of-all-pairs, task-scheduler,
projection-area-of-3d-shapes, sum-of-remoteness-of-all-cells, maximum-total-reward-using-operations-ii.
One more systematic codegen fix landed:
- **`for i, x in enumerate(C): <mutate C[i+1]>`** (`ControlFlow.forEnumerateContainerMut?`): Python's
  live `enumerate` sees a later-index mutation on the next iteration; a snapshot `for` misses it. Lower to
  an index `while` re-reading `C[i]` (binds `(i, C[i])` fresh each step). `jsonMutatesName` already makes
  `C` mutable (subscript assign). Fixes minimum-operations-to-make-binary-array-elements-equal-to-one-i.
Regression test extended (api_iteration_semantics.py `greedy_flips`).

REMAINING divergent (genuinely hard, ~12): backtracking flood-fill grid mutation in a recursive `dfs`
inside a `max(... for ...)` comprehension (path-with-maximum-gold 3/12, number-of-distinct-islands 8/12 —
value-semantics of a captured 2D grid restored between recursive calls); walrus+defaultdict+heapq
(split-array 6/12); memoized `@cache` DFS + `vis.add` side-effect (all-paths 11/12); 1-edge-case ones
(check-if-the-rectangle-corner-is-reachable 11/12, find-a-good-subset 11/12); factor-combinations 4/12,
modify-graph 2/12, number-of-beautiful-integers 7/12, before-and-after 2/12, lexicographically-smallest
0/12, least-operators 9/12 — assorted per-problem. Plus the always-deferred set-hash-order + float-2^64.

### Compile_fail mechanical batch — operator lib, polymorphic 2-arg pop, index(start)
Fresh random-120 (seed 3): ~86% convert. The compile_fails are dominated by HARD clusters (numeric-ℚ,
value-semantics Trie/SegmentTree ~24 "don't chase", PyAny over-boxing, nullable Option, tuple-vs-list).
Mechanical wins landed (all regression-safe; PALC runtime tests + dict_pop test pass):
- **`operator.truediv`/`operator.pow`** (Libraries/operator): added the missing members (`pyOperatorTrueDiv`
  via `/ₚ`, `pyOperatorPow` via `^ₚ`). evaluate-reverse-polish now converts (then hits a numeric int/float
  stack-type wall — separate).
- **2-arg dict pop `d.pop(k, default)` was `Std.HashMap`-only** → made `pyDictPopValue`/`pyDictPopRest`
  polymorphic over the `PyDictKeyPop` protocol (added `keyGetOr`; instances for `Std.HashMap` AND
  `PyDefaultDict`), so `Counter`/`defaultdict.pop(k, dflt)` work. Fixes count-of-sub-multisets, jump-game-iv.
- **`str.index(sub, start)` / `list.index(x, start)`** — the `PyIndex` protocol was 2-arg (couldn't take
  Python's optional `start`); added a `start` param (string routes to `pyStringIndex`'s optParams; list
  searches from `start`). Fixes repeated-substring-pattern.
Regression tests: PALC/PyAPI/TestStrings.lean (+pyIndex-start guards). HONEST NOTE: the mechanical
compile_fail vein is now largely exhausted (operator lib, polymorphic pop, index/startswith start-args
all done); the remaining ~200 compile_fails need TypeInfer (numeric/nullable/PyAny) or an architectural
value-semantics change (Trie/SegmentTree/tree-node reference mutation) — NOT one-by-one sweeps.

### TIMEOUTS — two systematic performance fixes (the overnight had 131 timeouts, mostly these)
The overnight eval's 141 "runtime-error/timeout" divergences were mostly two SYSTEMATIC perf bugs, not
slow algorithms — even binary-search problems (valid-perfect-square, koko-eating-bananas) timed out:
1. **`[x] * n` list-repeat was NOT array-backed** → `a[i] = v` was O(n) (value-semantics copies the whole
   list), so a sieve/DP-table (`primes = [True]*n; primes[j]=False`) was O(n²). `arrayEligibleVars`
   required a `List` *literal* init; `[x]*n` is a `BinOp mul`, so it was rejected. Fix: `litMatchesNesting`
   accepts `[x]*n` (safe — value semantics = n independent copies), `markSeqLit` stamps the repeat +its
   `[x]` operand `_seq:array`, and the BinOp codegen emits `pyArrayRepeat #[x] n` in the run twin (O(1)
   `a[i]=v`). Fixes count-primes (1/32 → 32/32).
2. **`bisect_left/right(range(a,b), x, key=f)` MATERIALIZED the range and mapped `key` over EVERY element
   (O(n))** — and `range(1, 10**9)` can't be materialized at all. Added lazy `pyBisectLeft/RightRangeKey
   (start stop step) x key` doing a real O(log n) binary search computing `key(start+mid*step)` on demand;
   `bisectRangeKeyed?` (CallExpr) detects a `Range` first arg and routes to it, passing the bounds instead
   of the materialized list. Fixes valid-perfect-square, koko-eating-bananas, minimum-speed-to-arrive-on-time,
   nth-magical-number, magnetic-force-between-two-balls, minimum-time-to-complete-trips (all timeout → 20/20).
Both are HIGH-leverage across the 131 timeouts (DP tables/sieves + binary-search-on-answer). Codegen
sweep clean; no-regression.

### TIMEOUTS 2 — nested (2D/3D+) array-backing for comprehension-built DP tables
Extended the `[x]*n` array-backing to ANY nesting level built by a COMPREHENSION (`[[inf]*(m) for _ in
range(n)]`, the 2D-DP idiom) — the biggest remaining timeout cluster:
- **Eligibility**: `litMatchesNesting` accepts a `ListComp`/`GeneratorExp` whose element matches the inner
  nesting; `markSeqLit` stamps the comprehension + its element `_seq:array`; the ListComp codegen emits
  `(… .map …) |>.toArray` (run twin only), rows via `pyArrayRepeat`.
- **O(1) nested update**: `f[i][j]=v` was `f := pySetItem f i (pySetItem (pyGetItem f i) j v)` — the
  `pyGetItem f i` SHARES the row, so `pySetItem` copies it (O(n)) → O(m·n²). New polymorphic `pyModifyItem`
  (Array → `Array.modify`, in-place O(1) when uniquely owned; List → O(n) as before; dict → insert) lets
  the codegen emit `f := pyModifyItem f i (fun row => pySetItem row j v)` for the OUTER levels of ANY-depth
  nested subscript-assign (`nestedSubscriptSetDoElem?` rewritten via `subscriptChain?`+`buildSubscriptSetRhs`).
Fixes coin-change (2/15→15/15), stone-game-v, longest-increasing-path-in-a-matrix, increment-submatrices-by-one;
perfect-squares/partition-equal-subset-sum improved (still timeout on the very largest 1D-DP cases — a
different bottleneck). Correct + no-regression: random-45 seed11 97.2%, 0 wrong-output; nested_array_mutation.py
(2D + 3D + coin-change) execution-verified == CPython. Regression test added.

REMAINING timeouts = inherently EXPONENTIAL backtracking (combination-sum/combinations output ALL combos —
exponential OUTPUT, not memoizable; matchsticks-to-square exponential-with-pruning). Our value-semantics +
closure-threading adds constant-factor overhead so we time out where CPython squeaks by; no clean fix
(memoization can't shrink an exponential output). These are the genuine tail.
