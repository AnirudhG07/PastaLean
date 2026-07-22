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

def maxArea(height: List[int]) -> int:
    l, r = (0, len(height) - 1)
    ans = 0
    while l < r:
        t = min(height[l], height[r]) * (r - l)
        ans = max(ans, t)
        if height[l] < height[r]:
            l += 1
        else:
            r -= 1
    return ans
