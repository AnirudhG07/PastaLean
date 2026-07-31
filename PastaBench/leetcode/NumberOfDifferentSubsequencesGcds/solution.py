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

def countDifferentSubsequenceGCDs(nums: List[int]) -> int:
    mx = max(nums)
    vis = set(nums)
    ans = 0
    for x in range(1, mx + 1):
        g = 0
        for y in range(x, mx + 1, x):
            if y in vis:
                g = gcd(g, y)
                if g == x:
                    ans += 1
                    break
    return ans
