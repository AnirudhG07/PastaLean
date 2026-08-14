from contracts import *


def is_happy(s: str):
    """You are given a string s.
    Your task is to check if the string is happy or not.
    A string is happy if its length is at least 3 and every 3 consecutive letters are distinct.
    """
    # Necessary condition (a genuine property of the function, not a bound): a string can only be
    # happy if it has length at least 3 — the guard rejects everything shorter before the scan.
    Ensures(Result() == False or len(s) >= 3)

    if len(s) < 3: return False
    Assert(len(s) >= 3)
    for i in range(len(s) - 2):
        Invariant(len(s) >= 3)
        Decreases(len(s) - 2 - i)
        if s[i] == s[i + 1] or s[i] == s[i + 2] or s[i + 1] == s[i + 2]:
            return False
    return True
