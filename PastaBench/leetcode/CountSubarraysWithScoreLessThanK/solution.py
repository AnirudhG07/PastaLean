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
    s = list(accumulate(nums, initial=0))
    ans = 0
    for i in range(1, len(s)):
        left, right = (0, i)
        while left < right:
            mid = left + right + 1 >> 1
            if (s[i] - s[i - mid]) * mid < k:
                left = mid
            else:
                right = mid - 1
        ans += left
    return ans
