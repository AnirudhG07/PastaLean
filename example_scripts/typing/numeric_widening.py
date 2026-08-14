#!/usr/bin/env python3
"""Numeric widening — a binder/container is typed by the JOIN of every value written to it
(design-choices.md §27). The hard part is that the widening SOURCE is only visible after desugaring
(chained assign) or only if a library call is typed (heappop), so these exercise the pipeline order
`desugar → infer` and the library-typing rules that keep an `unknown` from poisoning the join.
"""

from typing import List
from heapq import heappush, heappop


# Chained assign + true-division widening: `pre` starts int (0) via `ans = pre = 0`, then widens to ℚ
# via `pre = t`, where `t = a / b` is a true division. Splitting the chain per-target BEFORE inference
# is what lets `pre` be ℚ while `ans` stays int. (This is LeetCode car-fleet.)
def car_fleet(target: int, position: List[int], speed: List[int]) -> int:
    idx = sorted(range(len(position)), key=lambda i: position[i])
    ans = pre = 0
    for i in idx[::-1]:
        t = (target - position[i]) / speed[i]
        if t > pre:
            ans += 1
            pre = t
    return ans


# `heappush` must teach the heap its element type and `heappop` must return it, else `x` is `unknown`,
# `acc + x` is `unknown` (not float), and `acc` never widens to ℚ. Scalar-float heap (no tuple key).
def heap_float_sum(vals: List[int]) -> float:
    h: List[float] = []
    for v in vals:
        heappush(h, v / 2)
    acc = 0
    while h:
        acc = acc + heappop(h)
    return acc


# Container-element widening via an indexed write: `dist` starts `list[int]` (`[0]*n`), then a float
# write (`dist[i] = s / t`) widens the whole container to `List ℚ`, with the `0`s coerced.
def widen_container(n: int, s: int, t: int) -> float:
    dist = [0] * n
    dist[0] = 1
    for i in range(1, n):
        dist[i] = dist[i - 1] * s / t
    return dist[n - 1]


def main():
    print(car_fleet(12, [10, 8, 0, 5, 3], [2, 4, 1, 1, 3]))
    print(heap_float_sum([4, 2, 8, 6]))
    print(widen_container(4, 3, 2))


if __name__ == "__main__":
    main()
