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

def numSubarrayProductLessThanK(nums: List[int], k: int) -> int:
    ans = l = 0
    p = 1
    for r, x in enumerate(nums):
        p *= x
        while l <= r and p >= k:
            p //= nums[l]
            l += 1
        ans += r - l + 1
    return ans
