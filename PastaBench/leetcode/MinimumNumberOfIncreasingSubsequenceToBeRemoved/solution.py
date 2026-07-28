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

def minOperations(nums: List[int]) -> int:
    g = []
    for x in nums:
        l, r = (0, len(g))
        while l < r:
            mid = l + r >> 1
            if g[mid] < x:
                r = mid
            else:
                l = mid + 1
        if l == len(g):
            g.append(x)
        else:
            g[l] = x
    return len(g)
