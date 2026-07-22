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

def canSeePersonsCount(heights: List[int]) -> List[int]:
    n = len(heights)
    ans = [0] * n
    stk = []
    for i in range(n - 1, -1, -1):
        while stk and stk[-1] < heights[i]:
            ans[i] += 1
            stk.pop()
        if stk:
            ans[i] += 1
        stk.append(heights[i])
    return ans
