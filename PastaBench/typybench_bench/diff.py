"""Diagnose where PastaLean's *committed* repo-level types are WRONG (covered but low TypeSim).
Clusters (predicted -> ground-truth) mismatch patterns to expose systematic holes."""
import sys, json
from collections import Counter
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import score  # reuse extraction/inference


def render(node) -> str:
    if not isinstance(node, dict):
        return "?"
    nt = node.get("node_type")
    if nt == "Name":
        return norm(node.get("id", "Any"))
    if nt == "Constant":
        return "None" if node.get("value") is None else "?"
    if nt == "Attribute":
        return norm(node.get("attr", "Any"))
    if nt == "Tuple":
        return "tuple[" + ", ".join(render(e) for e in node.get("elts", [])) + "]"
    if nt == "Subscript":
        base = render(node.get("value"))
        sl = node.get("slice")
        if isinstance(sl, dict) and sl.get("node_type") == "Tuple":
            args = ", ".join(render(e) for e in sl.get("elts", []))
        elif isinstance(sl, dict) and sl.get("node_type") == "Index":
            return base + "[" + render(sl.get("value")) + "]"
        else:
            args = render(sl)
        if base == "Optional":
            return "Optional[" + args + "]"
        return base + "[" + args + "]"
    if nt == "BinOp":
        return render(node.get("left")) + " | " + render(node.get("right"))
    return "?"


def norm(s):
    return {"List": "list", "Dict": "dict", "Set": "set", "Tuple": "tuple", "FrozenSet": "frozenset",
            "Type": "type", "NoneType": "None"}.get(s, s)


def top(s):
    """Coarse bucket: strip args to the base head, so `list[X]` and `list[Y]` share a bucket."""
    return s.split("[")[0]


def analyze_repo(repo: Path):
    orig, untyped = repo / "original_repo", repo / "repo_without_types"
    for sub in ("src", "lib"):
        if (orig / sub).is_dir(): orig = orig / sub
        if (untyped / sub).is_dir(): untyped = untyped / sub
    gt = {}
    for py in orig.rglob("*.py"):
        m = score.module_name(py.relative_to(orig))
        ir = score.raw_ir(py)
        if ir: gt.update(score.extract_types(ir, m, gt=True))
    mods = {}
    for py in untyped.rglob("*.py"):
        m = score.module_name(py.relative_to(untyped))
        ir = score.raw_ir(py)
        if ir: mods[m] = ir
    gen_keys = score.generator_return_keys(untyped)
    stamped = score.infer_repo(mods)
    pred = {}
    for m, st in stamped.items():
        pred.update(score.extract_types(st, m, gt=False))
    score.apply_generator_returns(pred, gen_keys)
    score.apply_structural_returns(pred, score.structural_returns(untyped))
    return gt, pred


def main():
    repos = sys.argv[1:] or ["black", "agents", "deepface", "flask", "capa", "supervision", "lerobot", "gptme"]
    base = Path("/tmp/typybenchdata/typybenchdata")
    exact = wrong = 0
    pat = Counter()          # (pred_top -> gt_top) coarse pattern
    detail = Counter()       # full (pred -> gt) for the top buckets
    kindwrong = Counter()    # which key kind (@arg / return / var) is wrong
    for name in repos:
        gt, pred = analyze_repo(base / name)
        for k, gnode in gt.items():
            if k not in pred:
                continue
            gs, ps = render(gnode), render(pred[k])
            if gs == ps:
                exact += 1
            else:
                wrong += 1
                pat[(top(ps), top(gs))] += 1
                detail[(ps, gs)] += 1
                kindwrong["@arg" if "@" in k else ("return" if k.endswith("::return") else "var")] += 1
    cov = exact + wrong
    print(f"\ncovered={cov}  exact={exact} ({100*exact/cov:.0f}%)  wrong={wrong} ({100*wrong/cov:.0f}%)")
    print(f"wrong by kind: {dict(kindwrong)}")
    print("\n=== top COARSE mismatch patterns (pred_base -> gt_base) ===")
    for (p, g), c in pat.most_common(25):
        print(f"  {c:>5}   we say {p:<22} GT is {g}")
    print("\n=== top FULL mismatches (pred -> gt) ===")
    for (p, g), c in detail.most_common(20):
        print(f"  {c:>5}   {p:<26} -> {g}")


if __name__ == "__main__":
    main()
