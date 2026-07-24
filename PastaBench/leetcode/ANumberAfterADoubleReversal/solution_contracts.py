from contracts import *

def isSameAfterReversals(num: int) -> bool:
    Requires(num >= 0)
    Ensures(Result() == (num == 0 or num % 10 != 0))
    return num == 0 or num % 10 != 0