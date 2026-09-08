# A local variable's explicit annotation is authoritative and sticky: `acc: list[int] = []` stays
# `list[int]` even though it is built by appending, and the return follows it. Regression for the
# node_visitor dropping the annotation on an initialized `x: T = v` (collapsed to a plain Assign).
def collect(xs: list[int]) -> list[int]:
    acc: list[int] = []
    for x in xs:
        acc.append(x * 2)
    return acc


def counts(words: list[str]) -> dict[str, int]:
    d: dict[str, int] = {}
    for w in words:
        d[w] = d.get(w, 0) + 1
    return d


def main():
    print(collect([1, 2, 3]))
    print(counts(["a", "b", "a"]))
