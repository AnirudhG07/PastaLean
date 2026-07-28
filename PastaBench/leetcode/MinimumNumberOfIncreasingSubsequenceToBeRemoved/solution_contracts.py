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

def minOperations(nums: List[int]) -> int:
    Ensures(0 <= Result() <= len(nums))   # result is a nonnegative count no larger than the input length
    g = []
    for x in nums:
        l, r = 0, len(g)
        # binary-search [l, r) to find first index where g[idx] < x
        while l < r:
            mid = (l + r) >> 1
            Invariant(0 <= l)            # bounds for the search
            Invariant(l <= r)
            Invariant(r <= len(g))
            if g[mid] < x:
                r = mid
            else:
                l = mid + 1
        if l == len(g):
            g.append(x)
        else:
            Assert(l < len(g))          # safe to overwrite an existing slot
            g[l] = x
    return len(g)