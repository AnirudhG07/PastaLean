#!/usr/bin/env python3
"""pastaeval — one unified PastaLean evaluation harness.

Subsumes the three previous entry points:
  * PastaBench/run_humaneval_noncontract.sh  → `pastaeval humaneval`            (solution.py, no contracts)
  * PastaBench/run_humaneval_overnight.sh    → `pastaeval humaneval --contract` (solution_contracts.py; +--prove)
  * cp_harness/run_all.sh                    → `pastaeval cp [args…]`           (leetcode/CP via CPastaEval)

The numpy library + its tests are compile-checked in EVERY mode (they are shared and cheap), so any run
tells you whether numpy still elaborates alongside whatever else was checked.

Usage:
  python3 PastaBench/pastaeval.py humaneval               # non-contract: translate → compile
  python3 PastaBench/pastaeval.py humaneval --contract    # contract source; add --prove to run taste?
  python3 PastaBench/pastaeval.py cp --source leetcode --num max   # forwards remaining args to CPastaEval
  python3 PastaBench/pastaeval.py numpy                    # just the numpy files
  python3 PastaBench/pastaeval.py typeinfer                # TypeInfer vs TypeEvalPy micro-benchmark
  python3 PastaBench/pastaeval.py typeinfer -- --bench <autogen dir>   # the full autogen set

Do NOT run a separate `lake build` / `regen` concurrently — a warm backend + parallel `lake env lean`
share the oleans a build would rewrite.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import json
import pathlib
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
HE = ROOT / "PastaBench" / "humaneval"
OUT = ROOT / "PastaBench" / "_eval_out"

# numpy library + tests — plain `.lean`, compile-checked directly in every mode.
NUMPY_FILES = [
    ROOT / "Libraries" / "numpy" / "NumpyDef.lean",
    ROOT / "Libraries" / "numpy" / "TheoremsNumpy.lean",
    ROOT / "PALC" / "Libraries" / "numpy" / "numpy_test.lean",
    ROOT / "PALC" / "Libraries" / "numpy" / "numpy_extended_test.lean",
]


def log(msg: str) -> None:
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def _lean():
    from pastalean.backend import lean as lean_tools
    return lean_tools


def compile_file(path: pathlib.Path) -> tuple[bool, str]:
    """Elaborate one `.lean`; ok iff no errors (a `sorry` warning is fine)."""
    r = _lean().compile_check(lean_path=path, timeout=300)
    if r.ok:
        return True, ""
    errs = [d for d in (r.diagnostics or []) if getattr(d, "severity", "") == "error"]
    if errs:
        detail = str(errs[0])
    else:
        tail = (r.stderr or "").strip().splitlines()
        detail = tail[-1] if tail else "unknown error"
    return False, detail[:160]


def check_numpy() -> dict[str, str]:
    log(f"Compile-checking {len(NUMPY_FILES)} numpy files ...")
    out: dict[str, str] = {}
    for f in NUMPY_FILES:
        if not f.exists():
            out[f.name] = "MISSING"
            continue
        ok, err = compile_file(f)
        out[f.name] = "ok" if ok else f"FAIL: {err}"
        log(f"  numpy {f.name}: {out[f.name]}")
    return out


def run_humaneval(source: str, prove: bool, workers: int) -> dict:
    """Translate each problem's `source` (.py) through one warm backend, then compile-check 8-way."""
    OUT.mkdir(exist_ok=True)
    from pastalean import Session

    probs = sorted(d for d in HE.iterdir() if (d / source).exists() or (d / "solution.py").exists())
    log(f"HumanEval ({'contract' if source != 'solution.py' else 'non-contract'}"
        f"{', prove' if prove else ''}): translating {len(probs)} via one warm backend ...")

    status: dict[str, str] = {}
    detail: dict[str, str] = {}
    to_compile: dict[str, pathlib.Path] = {}

    with Session(target="command", mode="run", prove_asserts=prove) as s:
        for i, d in enumerate(probs, 1):
            name = d.name
            src = d / source
            if not src.exists():
                src = d / "solution.py"  # fall back to the plain solution when no contract file
            try:
                res = s.translate_file(src)
            except Exception as e:  # noqa: BLE001
                status[name] = "convert_fail"; detail[name] = f"exception: {e}"[:160]
                continue
            if not res.ok or not res.lean_code:
                status[name] = "convert_fail"; detail[name] = (res.error or "no lean")[:160]
                continue
            f = OUT / f"{name}.lean"
            f.write_text(res.lean_code)
            to_compile[name] = f
            if res.degraded:
                status[name] = "degraded"
            if i % 25 == 0:
                log(f"  translated {i}/{len(probs)}")

    log(f"Compile-checking {len(to_compile)} emitted files ({workers}-way) ...")
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(compile_file, f): name for name, f in to_compile.items()}
        done = 0
        for fut in concurrent.futures.as_completed(futs):
            name = futs[fut]
            ok, err = fut.result()
            if not ok:
                status[name] = "compile_fail"; detail[name] = err
            elif status.get(name) != "degraded":
                status[name] = "ok"
            done += 1
            if done % 25 == 0:
                log(f"  compiled {done}/{len(to_compile)}")

    return {"total": len(probs), "status": status, "detail": detail}


def run_humaneval_tests(source: str, workers: int) -> dict:
    """Translate each problem, then RUN its `fn'rn` twin over the `tests.json` cases and report how
    many pass (like the CP harness): builds a per-problem test `main`, executes `lake env lean --run`,
    parses `PASSED p/t`."""
    import ast
    OUT.mkdir(exist_ok=True)
    sys.path.insert(0, str(ROOT / "cp_harness"))
    from cpasta_eval import parse_test_input, build_test_harness, _PASSED_RE  # type: ignore
    from pastalean import Session
    lake = _lean().lake_executable()

    probs = sorted(d for d in HE.iterdir() if (d / "meta.json").exists() and (d / "tests.json").exists())
    log(f"HumanEval RUN: translating {len(probs)} via one warm backend ...")
    status: dict[str, tuple] = {}
    lean_code: dict[str, str] = {}
    with Session(target="command", mode="run", prove_asserts=False) as s:
        for d in probs:
            src = d / source
            if not src.exists():
                src = d / "solution.py"
            try:
                res = s.translate_file(src)
            except Exception as e:  # noqa: BLE001
                status[d.name] = (0, 0, "convert_fail"); continue
            if res.ok and res.lean_code:
                lean_code[d.name] = res.lean_code
            else:
                status[d.name] = (0, 0, "convert_fail")

    log(f"Building + running {len(lean_code)} test harnesses ({workers}-way) ...")

    def run_one(name: str) -> tuple[str, tuple]:
        d = HE / name
        meta = json.loads((d / "meta.json").read_text())
        method, params = meta["method"], meta.get("params", [])
        cases = []
        for t in json.loads((d / "tests.json").read_text()):
            try:
                args = parse_test_input(t["input"], params)
                expected = ast.literal_eval(t["output"])
                cases.append((args, expected))
            except Exception:  # noqa: BLE001
                continue
        if not cases:
            return name, (0, 0, "no_cases")
        data_path = OUT / f"{name}.json"
        # Non-contract translation emits `def <method>` inside `namespace PastaLean.User.Root` (no
        # `'rn` run-twin — that only appears in contract/proof output). The harness calls `<method>'rn`
        # at top level, so alias it (opening the namespace to resolve `<method>`).
        import re as _re
        code = lean_code[name]
        if f"{method}'rn" not in code:
            ns = _re.search(r'^namespace (\S+)', code, _re.M)
            opener = f"open {ns.group(1)} in\n" if ns else ""
            code = code + f"\n\n{opener}def {method}'rn := {method}\n"
        try:
            src, _runnable, data_json = build_test_harness(code, method, cases, data_path)
        except Exception as e:  # noqa: BLE001
            return name, (0, 0, "harness_fail")
        data_path.write_text(data_json)
        hpath = OUT / f"{name}_test.lean"
        hpath.write_text(src)
        try:
            proc = subprocess.run([lake, "env", "lean", "--run", str(hpath)],
                                  cwd=ROOT, capture_output=True, text=True, timeout=300)
        except subprocess.TimeoutExpired:
            return name, (0, 0, "timeout")
        m = _PASSED_RE.search(proc.stdout + proc.stderr)
        if not m:
            return name, (0, 0, "compile_fail")
        p, tt = int(m.group(1)), int(m.group(2))
        return name, (p, tt, "ok" if (tt > 0 and p == tt) else ("some_fail" if tt > 0 else "no_cases"))

    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(run_one, n): n for n in lean_code}
        done = 0
        for fut in concurrent.futures.as_completed(futs):
            name, r = fut.result()
            status[name] = r
            done += 1
            if done % 20 == 0:
                log(f"  ran {done}/{len(lean_code)}")
    return {"total": len(probs), "status": status}


def print_humaneval_run_report(res: dict) -> None:
    status = res["status"]
    passed_all = [n for n, (p, t, s) in status.items() if s == "ok"]
    some = {n: (p, t) for n, (p, t, s) in status.items() if s == "some_fail"}
    failed = {n: s for n, (p, t, s) in status.items() if s in ("compile_fail", "convert_fail", "timeout", "harness_fail", "no_cases")}
    tot_p = sum(p for p, t, s in status.values())
    tot_t = sum(t for p, t, s in status.values())
    print("\n" + "=" * 60)
    print("HUMANEVAL TEST-CASE RUN REPORT")
    print("=" * 60)
    print(f"  problems          : {res['total']}")
    print(f"  all cases pass    : {len(passed_all)}")
    print(f"  some cases fail   : {len(some)}")
    print(f"  couldn't run      : {len(failed)}")
    print(f"  total cases       : {tot_p}/{tot_t} passed")
    if some:
        print("-" * 60); print("  some cases fail (passed/total):")
        for n, (p, t) in sorted(some.items()):
            print(f"     {n:32s} {p}/{t}")
    if failed:
        print("-" * 60); print("  couldn't run:")
        for n, s in sorted(failed.items()):
            print(f"     {n:32s} {s}")


def print_humaneval_report(res: dict) -> None:
    from collections import Counter
    status, detail = res["status"], res["detail"]
    tally = Counter(status.values())
    print("\n" + "=" * 60)
    print("HUMANEVAL COMPILE REPORT")
    print("=" * 60)
    print(f"  total        : {res['total']}")
    print(f"  ok           : {tally.get('ok', 0)}")
    print(f"  degraded     : {tally.get('degraded', 0)}  (compiles; pyUnsupported placeholder)")
    print(f"  compile_fail : {tally.get('compile_fail', 0)}")
    print(f"  convert_fail : {tally.get('convert_fail', 0)}")
    for s in ("compile_fail", "convert_fail", "degraded"):
        ns = sorted(n for n, v in status.items() if v == s)
        if ns:
            print("-" * 60)
            print(f"  {s}:")
            for n in ns:
                print(f"     {n:32s} {detail.get(n, '')}")


def run_cp(passthrough: list[str]) -> int:
    log(f"Dispatching to CPastaEval: run {' '.join(passthrough)}")
    return subprocess.run(
        [sys.executable, str(ROOT / "cp_harness" / "cpasta_eval.py"), "run", *passthrough],
        cwd=ROOT,
    ).returncode


def run_typeinfer(passthrough: list[str]) -> dict:
    """Score the TypeInfer engine on the TypeEvalPy micro-benchmark (return/param/var exact match).
    Returns the leaderboard-style breakdown read back from the summary JSON."""
    out = ROOT / "PastaBench" / "_eval_out" / "typeinfer_summary.json"
    out.parent.mkdir(exist_ok=True)
    log("Dispatching to TypeInfer benchmark (TypeEvalPy)")
    rc = subprocess.run(
        [sys.executable, str(ROOT / "typeinfer_bench" / "typeinfer_eval.py"),
         "--out", str(out), *passthrough],
        cwd=ROOT,
    ).returncode
    breakdown = {}
    if out.is_file():
        breakdown = json.loads(out.read_text()).get("breakdown", {})
    return {"returncode": rc, "breakdown": breakdown}


def print_typeinfer_report(res: dict) -> None:
    b = res.get("breakdown", {})
    print("-" * 60)
    print("  TypeInfer (TypeEvalPy micro-benchmark) — exact-match breakdown:")
    print(f"    {'Dimension':24} {'Exact match':>14}")
    for dim in ("Function Return Type", "Function Parameter Type", "Local Variable Type", "Total"):
        d = b.get(dim)
        if d:
            pct = 100 * d["matched"] / d["total"] if d["total"] else 0.0
            print(f"    {dim:24} {d['matched']:>7} / {d['total']:<6} ({pct:.1f}%)")


def main() -> None:
    ap = argparse.ArgumentParser(prog="pastaeval", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    he = sub.add_parser("humaneval", help="compile-check the HumanEval suite (+numpy)")
    he.add_argument("--contract", action="store_true",
                    help="translate solution_contracts.py instead of solution.py")
    he.add_argument("--prove", action="store_true", help="run taste? proving (contract mode)")
    he.add_argument("--run", action="store_true",
                    help="RUN the tests.json cases against the 'rn twin and report pass rates (not just compile)")
    he.add_argument("--workers", type=int, default=8)

    cp = sub.add_parser("cp", help="run the competitive-programming (leetcode/CP) harness (+numpy)")
    cp.add_argument("passthrough", nargs=argparse.REMAINDER,
                    help="args forwarded verbatim to cp_harness/cpasta_eval.py run")

    sub.add_parser("numpy", help="compile-check only the numpy library + tests")

    ti = sub.add_parser("typeinfer",
                        help="score the TypeInfer engine on the TypeEvalPy micro-benchmark (return/param/var)")
    ti.add_argument("passthrough", nargs=argparse.REMAINDER,
                    help="args after `--` forwarded to typeinfer_bench/typeinfer_eval.py "
                         "(e.g. `typeinfer -- --bench <autogen dir>`)")

    args = ap.parse_args()
    report: dict = {}

    if args.cmd == "numpy":
        report["numpy"] = check_numpy()
    elif args.cmd == "humaneval":
        src = "solution_contracts.py" if args.contract else "solution.py"
        if args.run:
            he_res = run_humaneval_tests(src, workers=args.workers)
            print_humaneval_run_report(he_res)
        else:
            he_res = run_humaneval(src, prove=args.prove and args.contract, workers=args.workers)
            print_humaneval_report(he_res)
        report["humaneval"] = {k: (v if k != "status" else {n: list(x) if isinstance(x, tuple) else x
                                                             for n, x in v.items()}) for k, v in he_res.items()}
        report["numpy"] = check_numpy()  # numpy alongside, every mode
    elif args.cmd == "cp":
        rc = run_cp(args.passthrough)
        report["cp_returncode"] = rc
        report["numpy"] = check_numpy()
    elif args.cmd == "typeinfer":
        ti_res = run_typeinfer([a for a in args.passthrough if a != "--"])
        print_typeinfer_report(ti_res)
        report["typeinfer"] = ti_res
        out = ROOT / "PastaBench" / "pastaeval_report.json"
        out.write_text(json.dumps(report, indent=2, default=str))
        print(f"Full report: {out}")
        return

    print("-" * 60)
    print("  numpy:")
    for k, v in report.get("numpy", {}).items():
        print(f"     {k:28s} {v}")
    print("=" * 60)
    out = ROOT / "PastaBench" / "pastaeval_report.json"
    out.write_text(json.dumps(report, indent=2, default=str))
    print(f"Full report: {out}")


if __name__ == "__main__":
    main()
