from contracts import *

def sumOfTheDigitsOfHarshadNumber(x: int) -> int:
    Requires(x > 0)
    Ensures(Result() == -1 or x % Result() == 0)
    s, y = (0, x)
    while y:
        Invariant(y >= 0)
        Invariant(s >= 0)
        Decreases(y)
        s += y % 10
        y //= 10
    return s if x % s == 0 else -1