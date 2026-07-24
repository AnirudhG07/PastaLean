from contracts import *

def minOperations(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() == (n >> 1) * (n - (n >> 1)))
    return sum((n - (i << 1 | 1) for i in range(n >> 1)))