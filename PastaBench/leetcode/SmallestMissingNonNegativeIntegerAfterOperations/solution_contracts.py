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

def findSmallestInteger(nums: List[int], value: int) -> int:
    Requires(value > 0)
    # The function finds the smallest non-negative integer `k` (the "mex") that cannot be
    # constructed. A number `j` is constructible if we can find an unused number `x` in `nums`
    # such that `x % value == j % value`. Since each construction uses one number from `nums`,
    # we can construct at most `len(nums)` numbers. Therefore, the smallest unconstructible
    # number `k` must be in the range `0 <= k <= len(nums)`.
    Ensures(0 <= Result() <= len(nums))

    cnt = Counter((x % value for x in nums))
    for i in range(len(nums) + 1):
        Invariant(0 <= i <= len(nums))
        if cnt[i % value] == 0:
            return i
        cnt[i % value] -= 1
    # This path is logically unreachable. The loop is guaranteed to return a value `i`
    # where `i <= len(nums)`, because at most `len(nums)` numbers can be constructed.