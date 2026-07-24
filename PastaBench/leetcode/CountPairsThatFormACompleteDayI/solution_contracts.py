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

def countCompleteDayPairs(hours: List[int]) -> int:
    Ensures(
        Result() ==
        sum(
            1
            for i in range(len(hours))
            for j in range(i + 1, len(hours))
            if (hours[i] + hours[j]) % 24 == 0
        )
    )
    cnt = Counter()
    ans = 0
    # ghost index to track how many have been processed
    i = 0
    for x in hours:
        Invariant(0 <= i)
        Invariant(i <= len(hours))
        # ans counts exactly the complete-day pairs among the first i entries
        Invariant(
            ans
            == sum(
                1
                for p in range(i)
                for q in range(p + 1, i)
                if (hours[p] + hours[q]) % 24 == 0
            )
        )
        # cnt[r] is the count of entries among the first i whose value mod 24 is r
        Invariant(
            all(
                cnt[r]
                == sum(1 for j in range(i) if hours[j] % 24 == r)
                for r in range(24)
            )
        )
        ans += cnt[(24 - x % 24) % 24]
        cnt[x % 24] += 1
        i += 1
    # bridge to the postcondition: now i == len(hours)
    Assert(ans == Result())
    return ans