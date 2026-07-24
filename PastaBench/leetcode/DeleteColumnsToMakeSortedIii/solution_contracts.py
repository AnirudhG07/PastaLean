from contracts import *
from typing import List

def minDeletionSize(strs: List[str]) -> int:
    Requires(len(strs) > 0)
    Requires(all(len(s) == len(strs[0]) for s in strs))

    n = len(strs[0])
    f = [1] * n
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i < n)
        Decreases(n - i)
        for j in range(i):
            Invariant(0 <= j)
            Invariant(j < i)
            Decreases(i - j)
            if all((s[j] <= s[i] for s in strs)):
                f[i] = max(f[i], f[j] + 1)
    return n - max(f)