#!/usr/bin/env python3
"""A nested function that MUTATES captured state, called inside a comprehension.

Under value semantics the mutation is threaded through each call, but a comprehension has no
statement position to thread through. Each such comprehension (an aggregator over a generator, or a
bare list/set/dict comprehension) is rewritten to its explicit accumulator loop, where the threaded
call lands in a statement and the mutated state carries across iterations. A comprehension is exactly
that loop by definition, so this is semantics-preserving.
"""

from typing import List


# `sum(dfs(i) for i in …)`: `dfs` mutates the captured `seen` set; the visited state must persist
# across the generator's iterations (a flood-fill / connected-components shape).
def count_components(n: int, adj: List[List[int]]) -> int:
    def dfs(i: int) -> int:
        if i in seen:
            return 0
        seen.add(i)
        for j in adj[i]:
            dfs(j)
        return 1
    seen = set()
    return sum(dfs(i) for i in range(n))


# A bare LIST comprehension whose element mutates captured `total` (via a helper that returns the
# running value): the accumulator loop threads `total` correctly.
def running(xs: List[int]) -> List[int]:
    def step(x: int) -> int:
        nonlocal total
        total += x
        return total
    total = 0
    return [step(x) for x in xs]


def main():
    print(count_components(6, [[1], [0, 2], [1], [4], [3], []]))  # 3
    print(running([1, 2, 3, 4]))                                  # [1, 3, 6, 10]


if __name__ == "__main__":
    main()
