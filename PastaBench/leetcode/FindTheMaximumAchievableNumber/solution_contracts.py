from contracts import *

def theMaximumAchievableX(num: int, t: int) -> int:
    Requires(t >= 0)
    Ensures(Result() == num + 2 * t)
    return num + t * 2