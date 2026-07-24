from contracts import *

def minBitFlips(start: int, goal: int) -> int:
    Ensures(Result() == (start ^ goal).bit_count())
    return (start ^ goal).bit_count()