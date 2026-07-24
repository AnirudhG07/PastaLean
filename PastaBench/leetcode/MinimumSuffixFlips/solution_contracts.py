from contracts import *

def minFlips(target: str) -> int:
    Requires(all(c in '01' for c in target))
    ans = 0
    for v in target:
        if ans & 1 ^ int(v):
            ans += 1
    return ans