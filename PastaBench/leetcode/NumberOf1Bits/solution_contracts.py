from contracts import *


def hammingWeight(n: int) -> int:
    Requires(n >= 0)
    Decreases(n)
    ans = 0
    while n:
        n &= n - 1
        ans += 1
    return ans