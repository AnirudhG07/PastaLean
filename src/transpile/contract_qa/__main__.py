"""CLI: `python -m pastalean.transpile.contract_qa <track-or-unit-dir> [...]`.

Also reachable as `python3 PastaBench/pastabench.py contracts`, which is this entry point with the
benchmark's track layout filled in.

LLM budget: `--attempts 0` makes **zero** calls — the static, behaviour, contract-truth and
mutation gates are all deterministic. Each attempt above that costs at most one generation call per
unit that still needs one (plus one critic call, only with `--critic`). A unit that already passes
costs nothing.
"""

from __future__ import annotations

import argparse
import sys

from .harness import aggregate, check_unit, summarize
from .llm_io import have_key, llm_critic, llm_generator, no_critic
from .pipeline import repair_unit, write_report
from .unit import discover_units


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="contract-qa", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("root", help="a track directory (PastaBench/humaneval) or one unit directory")
    p.add_argument("--only", nargs="*", default=None, help="restrict to these module names")
    p.add_argument("--attempts", type=int, default=2,
                   help="max LLM generations per unit that needs one; 0 = verify only, no LLM calls")
    p.add_argument("--mutants", type=int, default=30, help="mutants per unit (0 disables)")
    p.add_argument("--mutation-tests", type=int, default=12,
                   help="recorded inputs each mutant is run against")
    p.add_argument("--min-mutation-score", type=float, default=None,
                   help="regenerate when the spec kills fewer than this fraction of live mutants")
    p.add_argument("--critic", action="store_true",
                   help="also ask the advisory LLM reviewer (one extra call per repair turn)")
    p.add_argument("--test-limit", type=int, default=50)
    p.add_argument("--workers", type=int, default=4)
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--timeout", type=float, default=300.0, help="wall clock per unit")
    p.add_argument("--report", default=None, help="write the full JSON report here")
    p.add_argument("--provider", default="gemini")
    p.add_argument("--model", default=None)
    p.add_argument("--in-place", action="store_true",
                   help="overwrite solution_contracts.py (default: write to _contract_qa/)")
    p.add_argument("--out-dir", default=None)
    p.add_argument("--verbose", "-v", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    dirs = discover_units(args.root, args.only)
    if not dirs:
        print("[!] no units found", file=sys.stderr)
        return 1

    attempts = args.attempts
    if attempts and not have_key(args.provider):
        print(f"[!] no API key for {args.provider} — falling back to a verify-only sweep "
              f"(the deterministic gates need none)")
        attempts = 0

    check_kwargs = dict(mutants=args.mutants, test_limit=args.test_limit,
                        mutation_tests=args.mutation_tests, seed=args.seed,
                        wall_timeout=args.timeout)
    print(f"[*] {len(dirs)} units, {args.mutants} mutants each, "
          f"up to {attempts} LLM attempt(s) per unit\n")
    print("STATUS    tests      E#  mutation        W#  module")

    reports = []
    if attempts:
        generator = llm_generator(args.provider, args.model)
        critic = llm_critic(args.provider, args.model) if args.critic else no_critic
        for d in dirs:
            r = repair_unit(d, generator=generator, attempts=attempts, critic=critic,
                            min_mutation_score=args.min_mutation_score,
                            out_dir=args.out_dir, in_place=args.in_place, **check_kwargs)
            reports.append(r)
            print(summarize(r) + (f"  -> {r['written']}" if r.get("written") else ""))
            if args.verbose:
                for line in r.get("diagnostics", [])[:8]:
                    print("      " + line)
    else:
        import concurrent.futures

        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(check_unit, d, **check_kwargs): d for d in dirs}
            for fut in concurrent.futures.as_completed(futures):
                r = fut.result()
                reports.append(r)
                print(summarize(r))
                if args.verbose:
                    for line in r.get("diagnostics", [])[:8]:
                        print("      " + line)
        reports.sort(key=lambda r: r["module"])

    summary = aggregate(reports)
    print("\n[*] " + ", ".join(f"{k}={v}" for k, v in sorted(summary["status"].items())))
    if summary["static_error_kinds"]:
        print("[*] static errors: "
              + ", ".join(f"{k}={v}" for k, v in sorted(summary["static_error_kinds"].items())))
    m = summary["mutation"]
    if m["mean_score"] is not None:
        print(f"[*] mutation: mean {m['mean_score']:.2f} over {m['scored_units']} scored units, "
              f"{m['vacuous_units']} vacuous (score 0), {m['perfect_units']} perfect")
    print(f"[*] LLM calls: {summary['llm_calls']}")
    if args.report:
        write_report(reports, args.report)
        print(f"[*] report -> {args.report}")
    return 0 if summary["status"].get("pass", 0) == len(reports) else 1


if __name__ == "__main__":
    raise SystemExit(main())
