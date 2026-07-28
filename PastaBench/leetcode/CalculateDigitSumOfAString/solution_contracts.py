from contracts import *


def digitSum(s: str, k: int) -> str:
    Requires(k > 0)
    Requires(s.isdigit())
    Ensures(len(Result()) <= k)
    while len(s) > k:
        Invariant(len(s) > k)
        Invariant(s.isdigit())
        t = []
        n = len(s)
        for i in range(0, n, k):
            Invariant(0 <= i)
            Invariant(i < n)
            x = 0
            for j in range(i, min(i + k, n)):
                Invariant(0 <= j)
                Invariant(j < n)
                x += int(s[j])
            t.append(str(x))
        s = ''.join(t)
    Assert(len(s) <= k)
    return s