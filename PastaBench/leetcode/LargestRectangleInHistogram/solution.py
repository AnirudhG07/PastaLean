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

def largestRectangleArea(heights: List[int]) -> int:
    n = len(heights)
    stk = []
    left = [-1] * n
    right = [n] * n
    for i, h in enumerate(heights):
        while stk and heights[stk[-1]] >= h:
            right[stk[-1]] = i
            stk.pop()
        if stk:
            left[i] = stk[-1]
        stk.append(i)
    return max((h * (right[i] - left[i] - 1) for i, h in enumerate(heights)))
