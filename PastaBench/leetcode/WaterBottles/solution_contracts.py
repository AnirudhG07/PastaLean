from contracts import *


def numWaterBottles(numBottles: int, numExchange: int) -> int:
    Requires(numBottles >= 0)
    Requires(numExchange > 1)
    orig = numBottles
    Ensures(Result() == orig + (orig - 1) // (numExchange - 1))
    ans = numBottles
    while numBottles >= numExchange:
        Invariant(orig >= numBottles)
        Invariant(numBottles >= 0)
        Invariant((numExchange - 1) * (ans - orig) == orig - numBottles)
        Decreases(numBottles)
        numBottles -= numExchange - 1
        ans += 1
    return ans