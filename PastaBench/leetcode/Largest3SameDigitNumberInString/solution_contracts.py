from contracts import *

def largestGoodInteger(num: str) -> str:
    Ensures(Result() == "" or Result() in num)    # ← the point: the result is a substring of num (or empty if none)
    for i in range(9, -1, -1):
        s = str(i) * 3
        if s in num:
            Assert(s in num)   # USEFUL: bridges the guard so we know s is in num here
            return s
    return ""