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

def maxRunTime(n: int, batteries: List[int]) -> int:
    Requires(n > 0)
    Requires(all(x >= 0 for x in batteries))
    Ensures(sum(min(x, Result()) for x in batteries) >= n * Result())
    l, r = 0, sum(batteries)
    while l < r:
        Decreases(r - l)
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(sum(min(x, l) for x in batteries) >= n * l)
        mid = l + r + 1 >> 1
        if sum((min(x, mid) for x in batteries)) >= n * mid:
            Assert(sum(min(x, mid) for x in batteries) >= n * mid)
            l = mid
        else:
            r = mid - 1
    return l