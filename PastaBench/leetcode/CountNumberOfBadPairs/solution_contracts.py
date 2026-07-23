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


def countBadPairs(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    cnt = Counter()
    ans = 0
    for i, x in enumerate(nums):
        Invariant(0 <= i)
        Invariant(i < len(nums))
        Invariant(ans >= 0)
        # cnt[i - x] is the count of previous indices j< i with j - nums[j] == i - x, so ≤ i
        Invariant(cnt[i - x] <= i)
        ans += i - cnt[i - x]
        cnt[i - x] += 1
    return ans