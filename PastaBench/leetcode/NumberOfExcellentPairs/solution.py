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

def countExcellentPairs(nums: List[int], k: int) -> int:
    s = set(nums)
    ans = 0
    cnt = Counter()
    for v in s:
        cnt[v.bit_count()] += 1
    for v in s:
        t = v.bit_count()
        for i, x in cnt.items():
            if t + i >= k:
                ans += x
    return ans
