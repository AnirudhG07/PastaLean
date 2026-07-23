from contracts import *

def queryString(s: str, n: int) -> bool:
    Requires(n >= 0)
    if n > 1000:
        return False
    Assert(n <= 1000)
    return all((bin(i)[2:] in s for i in range(n, n // 2, -1)))