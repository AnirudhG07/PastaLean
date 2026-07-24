from contracts import *

def sumBase(n: int, k: int) -> int:
    Requires(n >= 0)
    Requires(k >= 2)
    Ensures(Result() >= 0)

    ans = 0
    while n:
        Invariant(n >= 0)
        Invariant(ans >= 0)
        Decreases(n)
        ans += n % k
        n //= k
    return ans