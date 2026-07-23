from contracts import *

def consecutiveNumbersSum(n: int) -> int:
    Requires(n >= 1)
    Ensures(Result() >= 1)
    n <<= 1
    ans, k = (0, 1)
    while k * (k + 1) <= n:
        Invariant(k >= 1)
        Invariant(ans >= 0)
        Invariant(n - k * (k + 1) >= 0)
        Decreases(n - k * (k + 1))
        if n % k == 0 and (n // k - k + 1) % 2 == 0:
            ans += 1
        k += 1
    return ans