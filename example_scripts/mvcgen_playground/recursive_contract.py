from contracts import *


def countdown(n: int) -> int:
    Ensures(Result() == 0)
    return 0 if n <= 0 else countdown(n - 1)
