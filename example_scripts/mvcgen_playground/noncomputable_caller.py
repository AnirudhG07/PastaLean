from contracts import *


def sqrt_floor_plus_one(n: int) -> int:
    Ensures(Result() >= 1)
    def approx_sqrt(a: int) -> int:
        return int(a ** 0.5)
    return approx_sqrt(n) + 1
