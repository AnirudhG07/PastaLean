from contracts import *

def distinctIntegers(n: int) -> int:
    Ensures(Result() >= 1)
    return max(1, n - 1)