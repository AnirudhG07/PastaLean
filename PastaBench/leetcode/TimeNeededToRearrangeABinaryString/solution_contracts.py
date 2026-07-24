from contracts import *

def secondsToRemoveOccurrences(s: str) -> int:
    Ensures(Result() >= 0)
    ans = 0
    while s.count('01'):
        s = s.replace('01', '10')
        ans += 1
    Assert(s.count('01') == 0)
    return ans