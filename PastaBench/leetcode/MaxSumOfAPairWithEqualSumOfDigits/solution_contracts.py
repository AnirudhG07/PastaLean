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
from contracts import *

def maximumSum(nums: List[int]) -> int:
    Requires(all(v >= 0 for v in nums))
    Ensures(Result() >= -1)
    Ensures(len(nums) <= 1 or Result() == -1)
    d = defaultdict(int)
    ans = -1
    for v in nums:
        Invariant(ans >= -1)
        Invariant(all(val >= 0 for val in d.values()))
        x, y = (0, v)
        while y:
            Invariant(y >= 0)
            Invariant(x >= 0)
            Decreases(y)
            x += y % 10
            y //= 10
        if x in d:
            ans = max(ans, d[x] + v)
        d[x] = max(d[x], v)
    return ans