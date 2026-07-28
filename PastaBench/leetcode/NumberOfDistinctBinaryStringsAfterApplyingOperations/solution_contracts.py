from contracts import *

def countDistinctStrings(s: str, k: int) -> int:
    Requires(k >= 0)
    Requires(k <= len(s) + 1)
    return pow(2, len(s) - k + 1) % (10 ** 9 + 7)