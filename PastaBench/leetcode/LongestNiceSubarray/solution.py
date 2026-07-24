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

def longestNiceSubarray(nums: List[int]) -> int:
    ans = mask = l = 0
    for r, x in enumerate(nums):
        while mask & x:
            mask ^= nums[l]
            l += 1
        mask |= x
        ans = max(ans, r - l + 1)
    return ans
