from contracts import *


def is_happy(s: str):
    """You are given a string s.
    Your task is to check if the string is happy or not.
    A string is happy if its length is at least 3 and every 3 consecutive letters are distinct
    For example:
    is_happy(a) => False
    is_happy(aa) => False
    is_happy(abcd) => True
    is_happy(aabb) => False
    is_happy(adb) => True
    is_happy(xyy) => False
    """
    Ensures(Result() == (len(s) >= 3 and all(
        s[j] != s[j + 1] and s[j] != s[j + 2] and s[j + 1] != s[j + 2]
        for j in range(len(s) - 2)
    )))

    if len(s) < 3: return False
    Assert(len(s) >= 3)
    for i in range(len(s) - 2):
        Invariant(0 <= i <= len(s) - 2)
        Invariant(all(
            s[j] != s[j + 1] and s[j] != s[j + 2] and s[j + 1] != s[j + 2]
            for j in range(i)
        ))
        Decreases(len(s) - 2 - i)
        if s[i] == s[i + 1] or s[i] == s[i + 2] or s[i + 1] == s[i + 2]:
            return False
    return True