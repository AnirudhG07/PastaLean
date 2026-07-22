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

def maximumSum(nums: List[int]) -> int:
    n = len(nums)
    ans = 0
    for k in range(1, n + 1):
        t = 0
        j = 1
        while k * j * j <= n:
            t += nums[k * j * j - 1]
            j += 1
        ans = max(ans, t)
    return ans
