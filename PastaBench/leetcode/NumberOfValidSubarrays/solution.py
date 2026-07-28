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

def validSubarrays(nums: List[int]) -> int:
    n = len(nums)
    right = [n] * n
    stk = []
    for i in range(n - 1, -1, -1):
        while stk and nums[stk[-1]] >= nums[i]:
            stk.pop()
        if stk:
            right[i] = stk[-1]
        stk.append(i)
    return sum((j - i for i, j in enumerate(right)))
