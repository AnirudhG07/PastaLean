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

def maximumScore(nums: List[int], multipliers: List[int]) -> int:

    @cache
    def f(i, j, k):
        if k >= m or i >= n or j < 0:
            return 0
        a = f(i + 1, j, k + 1) + nums[i] * multipliers[k]
        b = f(i, j - 1, k + 1) + nums[j] * multipliers[k]
        return max(a, b)
    n = len(nums)
    m = len(multipliers)
    return f(0, n - 1, 0)
