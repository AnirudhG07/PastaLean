# LeetCode corpus fix campaign

Systematic, one-root-cause-at-a-time push to compile+build the ~810 failing
`cp_harness/dataset_leetcode` solutions. Baseline (convert stage, pre-campaign):
**1779 ok / 657 compile_fail / 153 convert_fail** out of 2589.

## How to work a theme

1. Re-run convert on **just that theme's problems** at HEAD — fast, and it auto-drops
   any already fixed by earlier work:
   ```bash
   python3 cp_harness/cpasta_eval.py convert --dataset cp_harness/dataset_leetcode \
     --problems <p1> <p2> ...     # problem list from themes.json[theme]["problems"]
   ```
   NOTE: a subset `convert` **overwrites** `dataset_leetcode/convert_summary.json` with
   only those problems. The immutable baseline is kept in `baseline_summary.json`; don't
   regenerate it. Rebuild `lake build` once before a theme so codegen changes are live.
2. Read the surviving errors, find the shared root cause, fix in `PastaLean/` / `TypeInfer/`
   / `Libraries/` (runtime vs codegen split per CLAUDE.md).
3. Re-run the theme; tick each problem that now **compiles** (convert ok). "build" = it also
   survives the native eval link (checked in bulk at the end).
4. If a problem in a theme turns out to have a *different* root cause, move it to T11.

Problem lists per theme: `themes.json`. Raw error buckets: `buckets.json`.

## Themes, by size

Order chosen by tractability × count, not raw count — T1 is largest but is its own
sub-project (the TypeInfer engine, plan `linear-honking-pelican.md`), so it goes last.

| # | theme | cf | cvf | total | status | root cause |
|---|---|---|---|---|---|---|
| T9 | functools-cache | 0 | 12 | 12 | ☐ | `@cache`/`.cache_clear()` unsupported — make a no-op |
| T10 | counter-methods | 0 | 7 | 7 | ☐ | `Counter.most_common` / `.elements()` missing |
| T7 | sortedlist-bisect-kw | 6 | 10 | 16 | ☐ | `SortedList` type; `bisect_left(a,x,lo=,hi=,key=)` kwargs |
| T5 | tuple-targets | 0 | 15 | 15 | ☐ | nested tuple assign / comprehension unpack (D19 row 5) |
| T6 | option-field-proj | 10 | 0 | 10 | ☐ | `.val`/`.left` on `Option TreeNode` needs unwrap |
| T8 | listnode-treenode-fields | 6 | 0 | 6 | ☐ | `ListNode.new(next=…)` arg name; `.next` field |
| T2 | let-mut-rebind | 78 | 0 | 78 | ☐ | `let mut` cannot shadow / cross-type reassignment |
| T4 | genexp-rebind-state | 0 | 19 | 19 | ☐ | call inside GeneratorExp/lambda can't rebind threaded state (D19 row 3) |
| T3 | closures-mutual-rec | 0 | 38 | 38 | ☐ | nested-fn-as-value; mutually-recursive nested fns (D19 rows 2/4) |
| T1 | typeinfer-numeric | 495 | 0 | 495 | ☐ | element/index/binder types default to ℚ or stay unpinned — the TypeInfer engine |
| T11 | misc-long-tail | 62 | 52 | 114 | ☐ | grab-bag of ≤4-occurrence buckets; triage as we go |

Sum: 657 cf + 153 cvf = 810.

## Already fixed this session (verify-and-tick, not re-implement)

These buckets were in the baseline but addressed by commits `c9e13e1` / `f0b750f`;
re-running their problems should now pass. Fold survivors into their theme.

- `pop()`/value+mutate in sub-expression (9) — hoisting generalised
- `itertools.count` / `cycle` / `repeat` (1+) — unrolled
- `defaultdict(dict)` / `defaultdict(Counter)` (2) — factories added
- `bisect.insort*` (part of T7)
- `.islower()`/`.isupper()` correctness (not a compile failure, but on the list)

## Progress log

_(newest first; one line per theme closed)_

- **T4 genexp-rebind-state — partial (10/19 convert-clean).** A nested state-threading function
  called inside a comprehension is rewritten to its explicit accumulator loop, where the mutated
  state threads across iterations (`ClosureConvert.expandThreadedComprehension?` +
  `hoistThreadedComprs`). Covers `AGG(f(…) for …)` for sum/max/min/any/all/list/set/sorted/…, bare
  `[…]`/`{…}`/`{k:v …}` comprehensions, and comprehensions nested in a larger expression
  (`1 + sum(dfs(j) for j)`). Verified correct vs CPython (`number-of-connected-components`;
  regression `example_scripts/general/threaded_comprehension.py`). Remaining 9 need conditional
  threading (`c or dfs(…)`, `and not dfs(…)`, while-test) — short-circuit-preserving, harder — and
  the grid ones additionally hit a separate homogeneous-tuple-as-iterable bug
  (`dirs = (-1,0,1,0,-1)` + `pairwise`).
- **T9 functools-cache — done.** `@cache`/`@lru_cache` transparent; `cache_clear`/`cache_info` →
  functools no-op. Folded into the decorator framework (commit 32d3da9).
