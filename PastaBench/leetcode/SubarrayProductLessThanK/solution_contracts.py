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

def numSubarrayProductLessThanK(nums: List[int], k: int) -> int:
    Requires(k > 0)
    Ensures(Result() ==
            sum(1
                for i in range(len(nums))
                for j in range(i, len(nums))
                if math.prod(nums[i:j+1]) < k))
    ans = l = 0
    p = 1
    for r, x in enumerate(nums):
        Invariant(0 <= r)
        Invariant(r < len(nums))
        Invariant(ans ==
                  sum(1
                      for i in range(r)
                      for j in range(i, r)
                      if math.prod(nums[i:j+1]) < k))
        Invariant(0 <= l)
        Invariant(l <= r + 1)
        Invariant(p == math.prod(nums[l:r+1]))
        p *= x
        while l <= r and p >= k:
            Invariant(0 <= l)
            Invariant(l <= r + 1)
            Invariant(p == math.prod(nums[l:r+1]))
            Decreases(r + 1 - l)
            p //= nums[l]
            l += 1
        Assert(p < k)
        ans += r - l + 1
    return ans