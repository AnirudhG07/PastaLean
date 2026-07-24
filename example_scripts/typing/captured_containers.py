#!/usr/bin/env python3
"""Containers built in one scope and captured by a nested `def`.

Lambda lifting turns each capture into a real parameter, and Lean will not infer a `def`'s parameter
types from its body — so an un-inferred capture becomes `PyGetItem ?m …` and instance resolution
gets stuck. Each local below is only pinned down by a *later* statement, not by its initialiser.
"""

from collections import Counter, defaultdict
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


# `defaultdict`/`Counter` are backed by `PyDefaultDict`, NOT the plain dict a `dict[_,_]`
# annotation emits — so a captured one needs that exact type, not merely *a* type. `todo` is a list
# of pairs, and `i, j = todo[k]` reads a TUPLE out of it (not a list, despite the subscript).
def walk(pairs: List[List[int]]) -> int:
    graph = defaultdict(list)
    seen = Counter()
    todo = []
    for a, b in pairs:
        graph[a].append(b)
        seen[a] += 1
        todo.append((a, b))

    def total() -> int:
        acc = 0
        for k in range(len(todo)):
            i, j = todo[k]
            acc += len(graph[i]) + seen[i] + j
        return acc

    return total()


# A capturing helper passed as a VALUE (`key=`), not called directly. Lifting it leaves a partial
# application, so the wrapper lambda needs its parameter TYPED — an untyped binder is exactly what
# an inference-hungry callback cannot resolve.
def ranked(items: List[int], weights: List[int]) -> List[int]:
    def score(x: int) -> int:
        return x * weights[x % len(weights)]

    return sorted(items, key=score)


def main():
    print(pick([[1, 1], [2, 3]]))
    print(tally(["ab", "ab", "c"]))
    print(walk([[1, 2], [1, 3]]))
    print(ranked([1, 2, 3], [10, 1]))


if __name__ == "__main__":
    main()
