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

def totalSteps(nums: List[int]) -> int:
    stk = []
    ans, n = (0, len(nums))
    dp = [0] * n
    for i in range(n - 1, -1, -1):
        while stk and nums[i] > nums[stk[-1]]:
            dp[i] = max(dp[i] + 1, dp[stk.pop()])
        stk.append(i)
    return max(dp)
