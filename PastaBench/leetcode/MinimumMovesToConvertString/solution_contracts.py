from contracts import *

def minimumMoves(s: str) -> int:
    Ensures(Result() >= 0)
    ans = 0
    i = 0
    # termination measure: remaining length to process
    while i < len(s):
        Invariant(0 <= i)
        Invariant(i <= len(s))
        Invariant(ans >= 0)
        Decreases(len(s) - i)
        if s[i] == 'X':
            ans += 1
            i += 3
        else:
            i += 1
    return ans