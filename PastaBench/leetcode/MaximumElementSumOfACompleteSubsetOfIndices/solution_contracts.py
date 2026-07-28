from contracts import *

def maximumSum(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    n = len(nums)
    ans = 0
    for k in range(1, n + 1):
        Invariant(1 <= k)
        Invariant(k <= n)
        t = 0
        j = 1
        while k * j * j <= n:
            Invariant(1 <= j)
            Invariant(k * j * j <= n)
            Invariant(0 <= k * j * j - 1)
            Invariant(k * j * j - 1 < n)
            Decreases(n - k * j * j)
            t += nums[k * j * j - 1]
            j += 1
        ans = max(ans, t)
    return ans