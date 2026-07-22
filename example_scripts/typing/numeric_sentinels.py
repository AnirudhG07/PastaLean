#!/usr/bin/env python3
"""`float('inf')` used as a DP sentinel in an INTEGER context.

Python compares `-inf` against ints freely, but Lean needs one type per slot. A monomorphic `ℚ`
sentinel made `-inf` unusable inside an `-> int` function, so the sentinel is polymorphic in its
numeric type and the surrounding slot picks it.
"""

from typing import List

inf = float('inf')


# The sentinel flows through an int-annotated recursive DP.
def best_pair(rods: List[int]) -> int:
    def dfs(i: int, j: int) -> int:
        if i >= len(rods):
            return 0 if j == 0 else -inf
        ans = max(dfs(i + 1, j), dfs(i + 1, j + rods[i]))
        return max(ans, dfs(i + 1, abs(rods[i] - j)) + min(j, rods[i]))
    return dfs(0, 0)


# `inf` as a minimisation seed, still an int result.
def smallest(xs: List[int]) -> int:
    lo = inf
    for x in xs:
        lo = min(lo, x)
    return lo


# The same global in a float slot — must still be usable there.
def scaled(xs: List[float]) -> float:
    hi = -inf
    for x in xs:
        hi = max(hi, x * 2.0)
    return hi


def main():
    print(best_pair([1, 2, 3, 6]))
    print(smallest([4, 2, 9]))
    print(scaled([1.5, 0.5]))


if __name__ == "__main__":
    main()
