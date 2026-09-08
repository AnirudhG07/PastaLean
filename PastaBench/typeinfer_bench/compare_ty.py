#!/usr/bin/env python3
"""Head-to-head: PastaLean's TypeInfer vs Astral's `ty` on the TypeEvalPy micro-benchmark, scoring
BOTH on the identical set of plain module-level variable facts (name-keyed exact match).

Usage:  uv run python typeinfer_bench/compare_ty.py [--bench DIR]
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_ty import run_ty_on, load_gt_vars               # noqa: E402
from typeinfer_eval import collect, ann_root             # noqa: E402
from pastalean import Session                            # noqa: E402

DEFAULT_BENCH = Path("/tmp/TypeEvalPy/micro-benchmark/python_features")


def pastalean_vars(session, py):
    ir = session.to_json_ir_file(py)
    res = session.client.infer_types(ir)
    stamped = res.get("ast", res) if isinstance(res, dict) else res
    _, _, var_ann, _, _ = collect(stamped)
    return {k: ann_root(v) for k, v in var_ann.items()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bench", type=Path, default=DEFAULT_BENCH)
    args = ap.parse_args()
    snippets = sorted(args.bench.glob("*/*/main.py"))

    pl = {"m": 0, "c": 0}
    ty = {"m": 0, "c": 0}
    total = 0

    s = Session(target="command", mode="both")
    s.start()
    try:
        for py in snippets:
            gt = py.with_name("main_gt.json")
            if not gt.exists():
                continue
            facts = load_gt_vars(gt)
            if not facts:
                continue
            try:
                plp = pastalean_vars(s, py)
            except Exception:  # noqa: BLE001
                plp = {}
            typ = run_ty_on(py.read_text())
            for name, golds in facts:
                total += 1
                p = plp.get(name)
                t = typ.get(name)
                if p is not None:
                    pl["c"] += 1
                    if p in golds:
                        pl["m"] += 1
                if t is not None:
                    ty["c"] += 1
                    if t in golds:
                        ty["m"] += 1
    finally:
        s.close()

    print(f"\n=== Plain module-level variable facts: PastaLean vs ty (n={total}) ===")
    print(f"  {'Tool':10} {'exact':>14} {'coverage':>14}")
    print(f"  {'PastaLean':10} {pl['m']:>5}/{total} ({100*pl['m']/total:4.1f}%) "
          f"{pl['c']:>5}/{total} ({100*pl['c']/total:4.1f}%)")
    print(f"  {'ty (Astral)':10} {ty['m']:>5}/{total} ({100*ty['m']/total:4.1f}%) "
          f"{ty['c']:>5}/{total} ({100*ty['c']/total:4.1f}%)")


if __name__ == "__main__":
    main()
