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
    # The 65..90 window below is the ASCII uppercase range, so the input must be ASCII.
    Requires(all(ord(c) < 128 for c in s))
    # THE POINT: the answer is a sum of codes of uppercase letters, each of which lies in [65, 90].
    # Hence a *nonzero* answer is at least 65 (something uppercase must have contributed), and no
    # character can contribute more than 90. Neither fact is visible from the signature — both come
    # out of the accumulator, which is why the loop is written explicitly.
    Ensures(Result() == 0 or Result() >= 65)
    Ensures(Result() <= 90 * len(s))
    total = 0
    for i in range(len(s)):
        Invariant(0 <= i)
        Invariant(i <= len(s))
        Invariant(total == 0 or total >= 65)
        Invariant(total <= 90 * i)
        ch = s[i]
        if ch.isupper():
            total += ord(ch)
    Assert(total <= 90 * len(s))
    return total
