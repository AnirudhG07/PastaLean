from contracts import *

def titleToNumber(columnTitle: str) -> int:
    Requires(all('A' <= ch <= 'Z' for ch in columnTitle))
    ans = 0
    for c in map(ord, columnTitle):
        Assert(ord('A') <= c <= ord('Z'))
        ans = ans * 26 + c - ord('A') + 1
    return ans