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

def minimumRightShifts(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    n = len(nums)
    Ensures(
        Result() == -1 or
        (0 <= Result() < n and
         # rotated list is strictly increasing
         all(
             (nums[-Result():] + nums[:-Result()])[j-1] < (nums[-Result():] + nums[:-Result()])[j]
             for j in range(1, n)
         )
        )
    )
    i = 1
    # loop finds the first drop in the prefix
    while i < n and nums[i - 1] < nums[i]:
        Invariant(1 <= i)
        Invariant(i <= n)
        Invariant(all(nums[j - 1] < nums[j] for j in range(1, i)))
        Decreases(n - i)
        i += 1
    k = i + 1
    # loop checks the suffix wraps below nums[0] and remains strictly increasing
    while k < n and nums[k - 1] < nums[k] < nums[0]:
        Invariant(i + 1 <= k)
        Invariant(k <= n)
        Invariant(all(nums[j - 1] < nums[j] and nums[j] < nums[0] for j in range(i + 1, k)))
        Decreases(n - k)
        k += 1
    return -1 if k < n else n - i