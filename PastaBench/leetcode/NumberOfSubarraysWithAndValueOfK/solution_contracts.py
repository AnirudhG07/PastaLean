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

def countSubarrays(nums: List[int], k: int) -> int:
    Ensures(
        # the result is the number of subarrays whose bitwise-AND equals k
        Result()
        == sum(
            1
            for i in range(len(nums))
            for j in range(i, len(nums))
            if functools.reduce(lambda a, b: a & b, nums[i : j + 1]) == k
        )
    )
    ans = 0
    pre = Counter()
    for x in nums:
        cur = Counter()
        for y, v in pre.items():
            cur[x & y] += v
        cur[x] += 1
        # each count is non-negative, so ans stays >= 0
        Assert(cur[k] >= 0)
        ans += cur[k]
        pre = cur
    return ans