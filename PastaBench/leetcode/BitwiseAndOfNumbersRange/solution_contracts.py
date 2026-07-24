from contracts import *

def rangeBitwiseAnd(left: int, right: int) -> int:
    Requires(0 <= left <= right)
    Ensures(0 <= Result() <= left)
    while left < right:
        Invariant(0 <= left)
        Invariant(left <= right)
        Invariant(0 <= right)
        Invariant(right - left >= 1)
        Decreases(right - left)
        right &= right - 1
    Assert(right <= left)
    return right