from contracts import *

def digitSum(s: str):
    """Task
    Write a function that takes a string as input and returns the sum of the upper characters only'
    ASCII codes.

    Examples:
        digitSum("") => 0
        digitSum("abAB") => 131
        digitSum("abcCd") => 67
        digitSum("helloE") => 69
        digitSum("woArBld") => 131
        digitSum("aAaaaXa") => 153
    """
    # A sum of ASCII codes (all non-negative) is non-negative. Written as an explicit
    # accumulating loop so the invariant `total >= 0` carries the proof.
    Ensures(Result() >= 0)
    total = 0
    for ch in s:
        Invariant(total >= 0)
        if ch.isupper():
            total += ord(ch)
    return total
