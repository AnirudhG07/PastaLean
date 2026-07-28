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
