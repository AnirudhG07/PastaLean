# TypeInfer engine — failure list

Compiled from `cp_harness/overnight_leetcode.log` (231 fails) and the HumanEval non-contract
compile-fails (46). **~200 of the ~277 total fails are TypeInfer-rooted** (LeetCode 173/231;
HumanEval 46/46). Grouped below by the shared engine gap, most-impactful first.

## G1 — Wrong concrete type stamped (`Application type mismatch`)  · LeetCode 50 + HE 6
The engine stamps a type the body then contradicts. Two sub-shapes:
- **`List PyAny` element vs a defaulted lambda `ℤ`** — `[x+1 for x in l]` / `all(x<t for x in l)`
  becomes `List.map (fun x => …) (l : List PyAny)` but the op defaults `x:ℤ`. *(FIXED this session:
  usage element now refines the bare `list` annotation.)* — BelowThreshold, IncrList.
- **PyAny value passed where a concrete arg is required** — `helper x` wants `ℤ`/`String` but `x:PyAny`.
  LeetCode: android-unlock-patterns, beautiful-pairs, campus-bikes, cherry-pickup-ii, clone-binary-tree-with-random-pointer, …
  HumanEval: ByLength(→int), StrongestExtension(→str), MatchParens(→str), Minpath(→int).

## G2 — Container protocol on wrong/uninferred type (`synth-fail`/`stuck` on PyIterable/PyGetItem/PySlice/PyContains/PyKeys/PySetItem)  · LeetCode 45+9 + HE 9
Param left as a metavariable or inferred as the wrong container, so `PyIterable ?m`, `PyGetItem ?m`,
`PySlice (Array _)`, `PyContains …`, `PyKeys ?m` won't resolve.
- HumanEval — param iterated but never pinned: RemoveVowels, HexKey, SortedListSum,
  NumericalLetterGrade, LargestSmallestIntegers, UniqueDigits (all `PyIterable ?m X`);
  CheckDictCase (`PyKeys ?m`), ReverseDelete (`PyContains ?m`), FilterIntegers (`PyTyped ?m`).
- LeetCode: analyze-user-website-visit-pattern, apply-operations-to-make-string-empty,
  build-a-matrix-with-conditions, can-make-palindrome-from-substring, check-completeness-of-a-binary-tree, …

## G3 — Uninferred param → stuck stringify/introspect metavar  · HE 6 (partly fixed)
Param whose only use is `str(x)`/`isalpha`/`isdecimal`/`eval` etc.; nothing pins it so the string
protocol is stuck. *(FIXED this session for `str`/`repr`/`print`: Digits, Multiply, CircularShift.)*
Remaining: string METHODS/functions on a PyAny — CheckIfLastCharIsALetter, Solve161 (`pyIsAlpha`),
FixSpaces (`pyStringReplace`), DoAlgebra (`pyEval`), ValidDate (`pyIsDecimal`), DecodeCyclic.

## G4 — Numeric tower: ℝ vs ℚ vs Float vs ℤ  · LeetCode 12+3 + HE 3
`math.*` yields ℝ, `/` and float literals yield ℚ, `Float` twin differs — not unified across
`+`/return/tuple-unpack, or a Float/ℝ result forced into an ℤ/ℚ codomain.
- HumanEval: Tri (List Float vs List ℤ return), TriangleArea71 (Float vs ℤ), FindZero (PyAny vs Float).
- LeetCode: best-position-for-a-service-centre, binary-tree-cameras, kth-smallest-product-of-two-sorted-arrays;
  real-mode: coordinate-with-maximum-network-quality, minimum-area-rectangle-ii.

## G5 — Option / nullable mismatch  · LeetCode 7+2 + HE 2
`none` gets `Option ?m` where `PyAny` (or a concrete `Option τ`) is expected; nullable node params.
- HumanEval: CompareOne, NextSmallest (`none` vs PyAny in a ternary).
- LeetCode: amount-of-new-area-painted-each-day, check-knight-tour-configuration, falling-squares,
  find-mode-in-binary-search-tree; field-project: binary-tree-coloring-game.

## G6 — Recursive / empty-container return metavars  · LeetCode 2+2+4
- recursive-return-type (`dfs` return type unresolved): binary-tree-longest-consecutive-sequence-ii, reachable-nodes-with-restrictions.
- empty-dict/HashMap metavar: count-prefix-and-suffix-pairs-ii, number-of-same-end-substrings.
- match-pattern metavar (`List (?m arr)` in a `match`): bitwise-ors-of-subarrays, parse-lisp-expression, …

## G7 — Hashable(Option/class)  · LeetCode 3
`Std.HashMap`/`set` keyed by `Option TreeNode`/a class with no `Hashable`: closest-leaf-in-a-binary-tree,
number-of-boomerangs, height-of-binary-tree-after-subtree-removal-queries.

## G8 — Operator-instance numeric gap (`PyFloorDiv`/`PyHDiv` ℝ/ℤ)  · LeetCode 2
Not strictly inference — a missing operator instance the inferred types need:
count-the-number-of-substrings-with-dominant-ones (`PyFloorDiv ℝ ℤ`), evaluate-reverse-polish-notation.

---

### Non-TypeInfer fails (for reference — codegen / feature, not this engine)
LeetCode: unknown-const (15), compare→Prop-not-Bool (13), value+mutate-subexpr (5), walrus-in-BoolOp (4),
Decidable(≠) (2), for-tuple-unpack (1), let-mut mutation (1); unsupported library/feature (9).

### Fixed this session (0 → 20 of 46 HumanEval compile-fails)
Levers added to `TypeInfer/Solve.lean`: (a) numeric-literal arithmetic on an element/loop var → its
numeric type; (b) ordered comparison (`x < t`) → numeric; (c) `str/repr/print(x)` → box PyAny;
(d) bare-container annotation keeps a concrete usage-inferred element (`list` + `[x+1 …]` → `list[int]`).
