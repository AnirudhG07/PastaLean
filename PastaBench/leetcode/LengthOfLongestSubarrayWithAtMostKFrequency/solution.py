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
    cnt = defaultdict(int)
    ans = j = 0
    for i, x in enumerate(nums):
        cnt[x] += 1
        while cnt[x] > k:
            cnt[nums[j]] -= 1
            j += 1
        ans = max(ans, i - j + 1)
    return ans
