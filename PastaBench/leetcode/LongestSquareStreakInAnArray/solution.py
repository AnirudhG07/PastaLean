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

def longestSquareStreak(nums: List[int]) -> int:
    s = set(nums)
    ans = -1
    for v in nums:
        t = 0
        while v in s:
            v *= v
            t += 1
        if t > 1:
            ans = max(ans, t)
    return ans
