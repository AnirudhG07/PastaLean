from contracts import *
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

def longestConsecutive(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    s = set(nums)
    ans = 0
    d = defaultdict(int)
    for x in nums:
        y = x
        while y in s:
            s.remove(y)
            y += 1
        d[x] = d[y] + y - x
        ans = max(ans, d[x])
    return ans