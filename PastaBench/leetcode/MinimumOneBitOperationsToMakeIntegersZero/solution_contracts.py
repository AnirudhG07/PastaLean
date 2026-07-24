from contracts import *

def minimumOneBitOperations(n: int) -> int:
    Requires(n >= 0)
    Decreases(n)
    ans = 0
    while n:
        Invariant(n >= 0)
        Invariant(ans >= 0)
        ans ^= n
        n >>= 1
    return ans