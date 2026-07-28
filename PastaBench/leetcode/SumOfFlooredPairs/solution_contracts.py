from contracts import *
import random
import functools
import collections
import string
import math
import datetime
from typing import *
from functools import *
from collections import *
from itertools import *
from heapq import *
from bisect import *
from string import *
from operator import *
from math import *

def sumOfFlooredPairs(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Requires(all(n > 0 for n in nums))
    mod = 10 ** 9 + 7
    Ensures(0 <= Result())
    Ensures(Result() < mod)

    cnt = Counter(nums)
    mx = max(nums)
    s = [0] * (mx + 1)

    # Build prefix sums of counts: s[i] = number of elements <= i
    for i in range(1, mx + 1):
        Invariant(1 <= i)
        Invariant(i <= mx)
        s[i] = s[i - 1] + cnt[i]

    ans = 0
    # Sum floor divisions: for each y and each x, floor(x / y)
    for y in range(1, mx + 1):
        Invariant(1 <= y)
        Invariant(y <= mx)
        if cnt[y]:
            d = 1
            while d * y <= mx:
                Invariant(1 <= d)
                Invariant(d * y <= mx)
                Invariant(0 <= ans)
                Invariant(ans < mod)
                # Count how many x fall into [d*y, d*y + y - 1], multiply by d and by count of y's
                ans += cnt[y] * d * (s[min(mx, d * y + y - 1)] - s[d * y - 1])
                ans %= mod
                d += 1

    return ans