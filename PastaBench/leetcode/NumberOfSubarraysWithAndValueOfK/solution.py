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

def countSubarrays(nums: List[int], k: int) -> int:
    ans = 0
    pre = Counter()
    for x in nums:
        cur = Counter()
        for y, v in pre.items():
            cur[x & y] += v
        cur[x] += 1
        ans += cur[k]
        pre = cur
    return ans
