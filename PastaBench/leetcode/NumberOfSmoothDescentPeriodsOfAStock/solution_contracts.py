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

def getDescentPeriods(prices: List[int]) -> int:
    # No external precondition needed
    # We'll prove safety of all indexing and nonnegativity of the result
    ans = 0
    i = 0
    n = len(prices)
    Ensures(ans >= 0)  # the total count is always nonnegative
    # outer loop: scan start of each descent segment
    while i < n:
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(ans >= 0)
        Decreases(n - i)
        # inner loop: extend the descent run as long as each step drops by exactly 1
        j = i + 1
        while j < n and prices[j - 1] - prices[j] == 1:
            Invariant(0 <= j)
            Invariant(j <= n)
            Decreases(n - j)
            j += 1
        # at least the 1-day segment
        cnt = j - i
        Assert(cnt >= 1)
        # add number of sub-periods in this descent: 1 + 2 + ... + cnt
        ans += (1 + cnt) * cnt // 2
        i = j
    return ans