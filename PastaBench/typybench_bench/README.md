# Running TypyBench with PastaLean's TypeInfer

[TypyBench](https://github.com/typybench/typybench) (ICML 2025) is a **repository-level** type
inference benchmark: 50 untyped Python repos, scored by **TypeSim** (semantic type similarity, by
nesting depth), exact-match, and **TypeCheck** (mypy consistency). A tool must emit an *annotated copy*
of each repo; TypyBench extracts types via mypy from the prediction and the ground-truth `original_repo`
and compares.

This is a natural fit for PastaLean's **repo-level** engine (`TypeInfer/Repo.lean`): all cross-file
import resolution and inference happen in Lean; Python only parses each file to IR and writes the
inferred types back as annotations.

## Prerequisites

```bash
lake build typeinfer          # the standalone Mathlib-free inference exe
uv pip install -e .           # the pastalean package (for node_visitor IR)
```

## 1. Get the dataset

Download from the link in TypyBench's README (Google Drive) and unpack so each repo is
`<dataset>/<repo>/repo_without_types/` (+ `original_repo/`).

## 2. Generate predictions (PastaLean, all inference in Lean)

```bash
# one repo
python typybench_bench/predict.py <dataset>/<repo>/repo_without_types ./predictions/<repo>
# whole dataset
python typybench_bench/run_predictions.py <dataset> ./predictions
```

`predict.py` collects each file's raw IR (`resolve_imports=False`, so Python does **no** inference),
sends the whole repo to the exe's `inferRepo` task (one Lean fixpoint, cross-file both directions,
cycle-safe), then writes function param/return and assignment annotations back into a copy. It never
overwrites a user annotation and skips non-committal types (`Any`/`None`).

## 3. Evaluate (TypyBench's own harness)

In the TypyBench checkout (needs Docker):

```bash
python run.py --pred-path /abs/path/to/predictions --num-workers 10
# scores land in predictions/<repo>/<repo>_results_w_exact.csv (overall_score = TypySim, etc.)
```

## Notes / scope

- **v1 annotates** function parameters, return types, and simple `name = …` assignments (module- and
  function-scope), matched by name (SSA versions like `x'v1` map back to `x`). Tuple-unpack targets,
  attributes, and `with`/`for` targets are not yet annotated — a precision ceiling, not a correctness
  risk (unannotated slots count as "missing", never wrong).
- Types render straight from the IR's annotation-shaped nodes (`list[tuple[int, str]]`, …) via
  `ast.unparse`.
