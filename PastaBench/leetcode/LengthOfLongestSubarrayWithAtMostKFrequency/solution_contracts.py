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


def maxSubarrayLength(nums: List[int], k: int) -> int:
    Requires(k >= 0)
    Ensures(0 <= Result() <= len(nums))
    cnt = defaultdict(int)
    ans = j = 0
    for i, x in enumerate(nums):
        Invariant(0 <= j)
        Invariant(j <= i + 1)
        Invariant(ans >= 0)
        Invariant(ans <= i - j + 1)
        cnt[x] += 1
        while cnt[x] > k:
            cnt[nums[j]] -= 1
            j += 1
        ans = max(ans, i - j + 1)
    return ans