#!/usr/bin/env python3
"""Containers built in one scope and captured by a nested `def`.

Lambda lifting turns each capture into a real parameter, and Lean will not infer a `def`'s parameter
types from its body — so an un-inferred capture becomes `PyGetItem ?m …` and instance resolution
gets stuck. Each local below is only pinned down by a *later* statement, not by its initialiser.
"""

from typing import List


# `graph` starts as `{}`; its key/value types come from the loop that fills it, and the loop target
# is a TUPLE (`for a, b in pairs`) — which the inference used to skip entirely.
def pick(pairs: List[List[int]]) -> int:
    graph = {}
    for a, b in pairs:
        graph[a] = b

    def first_one() -> int:
        for u in graph.keys():
            if graph[u] == 1:
                return u
        return pairs[0][0]

    return first_one()


# `seen` is refined by `+=` through a subscript, and `buckets` by `.append` through a subscript.
def tally(words: List[str]) -> int:
    seen = {}
    buckets = {}
    for w in words:
        seen[w] = seen.get(w, 0) + 1
        buckets[len(w)] = []
    for w in words:
        buckets[len(w)].append(w)

    def score() -> int:
        total = 0
        for w in seen.keys():
            total += seen[w] + len(buckets[len(w)])
        return total

    return score()


def main():
    print(pick([[1, 1], [2, 3]]))
    print(tally(["ab", "ab", "c"]))


if __name__ == "__main__":
    main()
