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
    # The result counts all unordered pairs of entries whose hours sum to a full day (24h) modulo 24.
    Ensures(
        Result()
        == sum(
            1
            for i in range(len(hours))
            for j in range(i)
            if (hours[i] + hours[j]) % 24 == 0
        )
    )
    cnt = Counter()
    ans = 0
    # Index-style invariant: after processing i elements, ans is exactly the number of valid pairs
    # among the first i entries.
    for i in range(len(hours)):
        Invariant(0 <= i)
        Invariant(i <= len(hours))
        Invariant(
            ans
            == sum(
                1
                for p in range(i)
                for q in range(p)
                if (hours[p] + hours[q]) % 24 == 0
            )
        )
        x = hours[i]
        ans += cnt[(24 - x % 24) % 24]
        cnt[x % 24] += 1
    # Bridge to the postcondition: at exit i == len(hours)
    Assert(
        ans
        == sum(
            1
            for i in range(len(hours))
            for j in range(i)
            if (hours[i] + hours[j]) % 24 == 0
        )
    )
    return ans