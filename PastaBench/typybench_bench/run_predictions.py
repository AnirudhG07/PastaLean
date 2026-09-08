"""Batch: generate PastaLean predictions for a whole TypyBench dataset, ready for TypyBench's eval.

The TypyBench dataset (download link in its README) lays each repo out as:
    <dataset>/<repo>/repo_without_types/   <- untyped input a tool infers on
    <dataset>/<repo>/original_repo/        <- ground truth (well-typed)

This walks every repo, runs `predict.annotate_repo` on its `repo_without_types`, and writes the
annotated copy to `<out>/<repo>/`, i.e. exactly the `predictions/<repo>/` layout TypyBench's `run.py`
expects. Then:

    python typybench_bench/run_predictions.py <dataset> ./predictions
    python run.py --pred-path ./predictions --num-workers 10        # (in the typybench checkout)
"""
import sys
from pathlib import Path

from predict import annotate_repo  # same dir


def main(dataset: Path, out: Path):
    out.mkdir(parents=True, exist_ok=True)
    repos = sorted(p for p in dataset.iterdir() if (p / "repo_without_types").is_dir())
    print(f"[typybench] {len(repos)} repos under {dataset}")
    for repo in repos:
        dest = out / repo.name
        if dest.exists():
            print(f"  skip {repo.name} (exists)"); continue
        print(f"  == {repo.name} ==")
        try:
            annotate_repo(repo / "repo_without_types", dest)
        except Exception as e:  # noqa: BLE001
            print(f"     FAILED: {e}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__); sys.exit(1)
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    main(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
