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

def minPatches(nums: List[int], n: int) -> int:
    Requires(n >= 0)
    Requires(all(num > 0 for num in nums))
    Requires(nums == sorted(nums))

    x = 1
    ans = 0
    i = 0
    while x <= n:
        # x is the smallest unreachable sum so far, always >= 1
        Invariant(1 <= x)
        # i stays within valid indexing range for nums
        Invariant(0 <= i)
        Invariant(i <= len(nums))

        if i < len(nums) and nums[i] <= x:
            x += nums[i]
            i += 1
        else:
            ans += 1
            x <<= 1

    # At exit x > n, so all values in [1..n] are covered
    Assert(x > n)
    return ans