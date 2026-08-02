from contracts import *
import collections
from typing import *

def countPairs(deliciousness: List[int]) -> int:
    Requires(len(deliciousness) > 0)
    Requires(all(d >= 0 for d in deliciousness))
    Ensures(Result() >= 0)
    Ensures(Result() < 10**9 + 7)

    mod = 10 ** 9 + 7
    mx = max(deliciousness) << 1
    cnt = collections.Counter()
    ans = 0
    for d in deliciousness:
        Invariant(0 <= ans < mod)
        Invariant(all(v >= 0 for v in cnt.values()))

        s = 1
        while s <= mx:
            Invariant(s > 0 and (s & (s - 1)) == 0)
            Invariant(0 <= ans < mod)
            Decreases(mx + 1 - s)

            ans = (ans + cnt[s - d]) % mod
            s <<= 1
        cnt[d] += 1
    return ans