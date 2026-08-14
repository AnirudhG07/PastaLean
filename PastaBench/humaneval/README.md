# PastaBench — HumanEval+ track

The **164** problems of [`evalplus/humanevalplus`](https://huggingface.co/datasets/evalplus/humanevalplus)
(the hardened-test-set version of OpenAI HumanEval), ingested into the same per-problem layout as the
`leetcode/` track so the whole PastaBench pipeline (`contracts` → `regen` → `lake build`) applies
unchanged.

## Layout (per problem, `humaneval/<Module>/`)

| file | source |
|---|---|
| `solution.py` | the dataset `prompt` + `canonical_solution` (the full reference function) |
| `tests.json` | up to 50 `{ "input": "arg = val, …", "output": "repr" }` — the plus test inputs, with outputs computed by **running the canonical solution** on each |
| `problem.txt` | the function's docstring |
| `meta.json` | `task_id`, `method` (entry point), `params`, `n_tests`, … |
| `solution_contracts.py` | written by the LLM `contracts` pass |
| `Generated.lean` / `Proofs.lean` | the transpiler output + the human proof (two-file rule) |

Ingested by `/tmp/ingest_humaneval.py` (kept out of the repo; it only needs `datasets`): it execs each
canonical solution, drives the dataset's own test harness with an instrumented candidate to record
`(inputs, output)` pairs, and writes the dirs above. `manifest.json` lists all 164.

## The 7 problems that needed special handling

**All 164 are now ingested.** Two issues in the raw dataset had to be worked around:

### 1 problem — `find_zero` (HumanEval/32): test checks a *property*, not a value
Its harness asserts `poly(root) ≈ 0` (and the root is **not unique**), so there is no expected-value
list to read — the generic instrumentation records nothing, and the harness even crashes mid-loop
(`_poly(*root, …)` unpacks the float root with `*`). **Fix:** a fallback that reads the `inputs = [...]`
list straight out of the test's AST and runs the canonical `find_zero` on each input, recording the
*specific deterministic root* it returns (e.g. `xs = [-10, -2] → -5.0`). That is a well-defined,
reproducible test even though mathematically other roots exist.

### 6 name collisions (12 problems) — HumanEval reuses function names across different problems
`add`, `solve`, `sort_array`, `triangle_area`, `correct_bracketing`, and `sum_squares` each appear in
**two** distinct problems. A plain PascalCase of the entry point would collapse each pair into one
directory (losing 6 problems). **Fix:** collisions are disambiguated with the HumanEval task number:

| entry point | task ids | modules |
|---|---|---|
| `triangle_area` | 45, 71 | `TriangleArea45`, `TriangleArea71` |
| `add` | 53, 85 | `Add53`, `Add85` |
| `correct_bracketing` | 56, 61 | `CorrectBracketing56`, `CorrectBracketing61` |
| `solve` | 84, 161 | `Solve84`, `Solve161` |
| `sort_array` | 88, 116 | `SortArray88`, `SortArray116` |
| `sum_squares` | 133, 142 | `SumSquares133`, `SumSquares142` |

Non-colliding problems keep the clean name (`HasCloseElements`, `TruncateNumber`, …).

## Source edits: added type annotations

HumanEval solutions are usually **unannotated** (`def digits(n):`), so PastaLean's type inference has
no hint and defaults the parameter to the dynamic `PyAny` box — which then fails to elaborate for
integer/string algorithms (e.g. `2 <= p` has no order on `PyAny`; a `HashMap PyAny` isn't decidable).
Python's own type *is* determined by the operations, and the `TypeInfer` pass now recovers many of
these from usage, so an annotation is only needed where the type is genuinely undecidable from the
body. The following had a type annotation added to their param(s) (in `solution.py`/
`solution_contracts.py`), and nothing else:

`count_up_to(n: int)`, `digits(n: int)`, `get_max_triples(n: int)`, `iscube(a: int)`,
`cycpattern_check(a: str, b: str)`, `is_sorted(lst: List[int])`, `sort_array(arr: List[int])`,
`unique_digits(x: List[int])`, `solve(s: str)`, `valid_date(date: str)`,
`words_in_sentence(sentence: str)`, `get_row(lst: List[List[int]], x: int)`,
`get_closest_vowel(word: str)` (see the str-vs-`list[str]` note below).

### TypeInfer improvements that removed some annotations (2026-08-09)

Two usage-inference fixes let previously-`PyAny` params resolve without a hint:

- **Container shape known, elements unknown → `PyAny` elements.** A param inferred `list[unknown]`
  (e.g. only from `arr == []`) used to fall back to bare `PyAny`; it now emits `List PyAny`, keeping
  the structural ops (iterate / index / `len` / `==`) while only the elements stay dynamic.
- **`<literal> in name` teaches the container's element.** `usageType` already handled `x in literal`;
  it now also reads `0 in arr ⇒ arr : list[int]` (name is the *container*). A `str` literal is excluded
  because `"a" in s` is ambiguous (substring on a `str` vs membership in a `list[str]`).

Together these let e.g. `prod_signs(arr)` infer `arr : List Int` with no annotation.

### A genuinely undecidable case: `str` vs `list[str]` — `get_closest_vowel` (HumanEval/118)

This one is **not** an inference bug we can fix — it is impossible in principle without a hint, and is
the clearest example of *why* some params must be annotated. `get_closest_vowel(word)` uses `word` only
as `word[i]`, `word[i] in "aeiouAEIOU"`, `is_vowel(word[i])`, and `return word[i]` / `return ""`. Every
one of these signals says the *element* `word[i]` is a `str` — but a Python **`str`** (indexed → 1-char
string) and a **`list[str]`** (indexed → element string) are *behaviourally identical* under indexing,
iteration, `len`, and element-string ops. Nothing in the body distinguishes them; even the return type
and the `Result() in word` postcondition stay consistent with both. So the type is **genuinely
ambiguous** — the same source is valid Python for either reading.

There is no *sound* automatic resolution. One could **default the char-ambiguous case to `str`** (the
overwhelming idiom, and what the test harness actually passes), but that silently mis-types a read-only
unannotated `list[str]` param (`def f(words): return words[0].upper()` — first-word-upper becomes
first-char-upper), trading a compile error for a *wrong answer*, which is worse. Name heuristics
(`word` vs `words`) are unreliable. We therefore **do not guess**: the parameter is annotated
`word: str`, which is the honest fix and exactly the information a real type checker would require. Flag
any similarly char-indexed unannotated param as needing a `str` / `list[str]` hint.

Known residual gaps (need the type-inference engine, not a param annotation):
- **Comprehension/`map` variable types** — in `decode_cyclic`, `group` iterates a `List[str]` but the
  codegen typed it `Int`; ascribing `group : String` fixes it. The element type should propagate to the
  loop/lambda variable.
- **`PyAny` equality** — `PyAny` has a (partial) `BEq` but no `DecidableEq`, so `native_decide`/`decide`
  can't compare boxed values; the fix is a structural `beq` + a reflection lemma (or full inference so
  values are never boxed in the first place).
- **`eval`** — `do_algebra` calls Python `eval` on a built arithmetic string; it needs a small
  precedence-respecting evaluator (`** > *,// > +,-`), not a general Python `eval`.

## Running the pipeline

The key is read from `.env` (repo root) automatically — this repo's `.env` has `GEMINI_API_KEY`, so
the default provider is `Gemini` (the same one used for the leetcode contracts). To generate contracts
+ Lean for every problem overnight and compile-check them:

```bash
nohup bash PastaBench/run_humaneval_overnight.sh > PastaBench/humaneval_overnight.log 2>&1 &
```

Do **not** run any other `lake build` / `cpasta_eval` while it runs — regen uses a warm Lean backend
and a concurrent build corrupts its oleans.
