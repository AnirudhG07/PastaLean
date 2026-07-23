from contracts import *
from typing import List

def minDeletion(nums: List[int]) -> int:
    n = len(nums)
    Requires(n >= 0)
    Ensures(0 <= Result() <= n)
    Ensures((n - Result()) % 2 == 0)    # final length after deletions is even
    i = 0
    ans = 0
    while i < n - 1:
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(0 <= ans)
        Invariant(ans <= n)
        Decreases(n - i)
        if nums[i] == nums[i + 1]:
            ans += 1
            i += 1
        else:
            i += 2
    # before parity fix, ans within bounds
    Assert(0 <= ans <= n)
    # ensure final length even
    ans += (n - ans) % 2
    Assert((n - ans) % 2 == 0)
    return ans