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
from contracts import *

def maxScore(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(Result() >= 0)
    stk = []
    for i, x in enumerate(nums):
        while stk and nums[stk[-1]] <= x:
            stk.pop()
        stk.append(i)
    ans = i = 0
    for j in stk:
        ans += nums[j] * (j - i)
        i = j
    return ans