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
    d = defaultdict(int)
    ans = -1
    for v in nums:
        x, y = (0, v)
        while y:
            x += y % 10
            y //= 10
        if x in d:
            ans = max(ans, d[x] + v)
        d[x] = max(d[x], v)
    return ans
