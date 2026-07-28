from contracts import *

def maxJump(stones: List[int]) -> int:
    Requires(len(stones) >= 2)
    ans = stones[1] - stones[0]
    for i in range(2, len(stones)):
        Invariant(2 <= i)
        Invariant(i < len(stones))
        ans = max(ans, stones[i] - stones[i - 2])
    return ans