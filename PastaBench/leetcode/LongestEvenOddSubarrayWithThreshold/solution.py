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

def longestAlternatingSubarray(nums: List[int], threshold: int) -> int:
    ans, n = (0, len(nums))
    for l in range(n):
        if nums[l] % 2 == 0 and nums[l] <= threshold:
            r = l + 1
            while r < n and nums[r] % 2 != nums[r - 1] % 2 and (nums[r] <= threshold):
                r += 1
            ans = max(ans, r - l)
    return ans
