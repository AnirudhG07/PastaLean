#!/usr/bin/env python3
"""Generate PastaBench/humaneval_report.txt: translate + compile-check every HumanEval `solution.py`
and record the FULL (untruncated) error for every non-OK result, plus a `pyUnsupported` degradation
flag. Read the report instead of re-running the sweep.

    python3 PastaBench/humaneval_report.py            # all 164
    python3 PastaBench/humaneval_report.py Encode Tri  # only the named problems (refresh a subset)

Verdicts:
  ok            translated + compiled clean, no `pyUnsupported`
  degraded      compiled, but best-effort inserted `pyUnsupported` (real logic lost)
  compile_fail  translated, but the emitted Lean did not elaborate
  convert_fail  the backend threw during translation
"""
import sys, subprocess, pathlib, re, concurrent.futures, json

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))
from pastalean import Session                                   # noqa: E402
from pastalean.backend import lean as _lean                     # noqa: E402

HE = ROOT / "PastaBench" / "humaneval"
GEN = ROOT / "PastaBench" / "_report_gen"
GEN.mkdir(exist_ok=True)
REPORT = ROOT / "PastaBench" / "humaneval_report.txt"
lake = _lean.lake_executable()


def main() -> None:
    sel = set(sys.argv[1:])
    probs = sorted(d.name for d in HE.iterdir()
                   if (d / "solution.py").exists() and (not sel or d.name in sel))

    codes, errs = {}, {}
    with Session(target="command", mode="run") as s:            # best-effort ON → pyUnsupported shows
        for n in probs:
            try:
                r = s.translate_file(HE / n / "solution.py")
            except Exception as e:                              # noqa: BLE001
                codes[n], errs[n] = None, f"{type(e).__name__}: {e}"
                continue
            if r.ok and r.lean_code:
                codes[n] = r.lean_code
                (GEN / f"{n}.lean").write_text(r.lean_code)
            else:
                codes[n], errs[n] = None, (r.error or "empty output")

    def compile_one(n: str):
        if codes[n] is None:
            return n, "convert_fail", errs[n]
        degraded = "pyUnsupported" in codes[n]
        p = subprocess.run([lake, "env", "lean", str(GEN / f"{n}.lean")],
                           cwd=ROOT, capture_output=True, text=True, timeout=300)
        out = (p.stdout + p.stderr).strip()
        if p.returncode == 0 and "error" not in out.lower():
            return n, ("degraded" if degraded else "ok"), (out if degraded else "")
        return n, "compile_fail", out

    results = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:
        for n, verdict, detail in ex.map(compile_one, probs):
            results[n] = (verdict, detail)

    order = {"convert_fail": 0, "compile_fail": 1, "degraded": 2, "ok": 3}
    counts = {}
    for v, _ in results.values():
        counts[v] = counts.get(v, 0) + 1

    # one-line error headline per non-ok, for the cluster summary
    def headline(detail: str) -> str:
        for ln in detail.splitlines():
            if "error" in ln.lower():
                m = re.search(r"error[^:]*:\s*(.*)", ln)
                h = (m.group(1) if m else ln).strip()
                if h:
                    return h
        nxt = [l.strip() for l in detail.splitlines() if l.strip()]
        return nxt[1] if len(nxt) > 1 else (nxt[0] if nxt else "?")

    clusters = {}
    for n, (v, d) in results.items():
        if v in ("compile_fail", "convert_fail"):
            key = re.sub(r"\d+", "N", headline(d))[:60]
            clusters.setdefault(key, []).append(n)

    lines = []
    total = len(probs)
    lines.append(f"HumanEval compile report — {total} problems")
    lines.append("  " + "  ".join(f"{k}={counts.get(k,0)}"
                                   for k in ("ok", "degraded", "compile_fail", "convert_fail")))
    lines.append("")
    lines.append("== failure clusters (by first error line) ==")
    for key in sorted(clusters, key=lambda k: -len(clusters[k])):
        lines.append(f"[{len(clusters[key])}] {key}")
        lines.append("      " + ", ".join(sorted(clusters[key])))
    lines.append("")
    lines.append("== per-problem (full errors) ==")
    for n in sorted(probs, key=lambda n: (order[results[n][0]], n)):
        v, d = results[n]
        if v == "ok":
            continue
        lines.append(f"----- {n}  [{v}] -----")
        lines.append(d if d else "(no output)")
        lines.append("")

    REPORT.write_text("\n".join(lines))
    json.dump({n: {"verdict": v, "detail": d} for n, (v, d) in results.items()},
              open(REPORT.with_suffix(".json"), "w"), indent=1)
    print(f"[*] {counts.get('ok',0)} ok, {counts.get('degraded',0)} degraded, "
          f"{counts.get('compile_fail',0)} compile_fail, {counts.get('convert_fail',0)} convert_fail")
    print(f"[*] wrote {REPORT}")


if __name__ == "__main__":
    main()
