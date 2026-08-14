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
inf = float('inf')

def shortestSubarray(nums: List[int], k: int) -> int:
    s = list(accumulate(nums, initial=0))
    q = deque()
    ans = inf
    for i, v in enumerate(s):
        while q and v - s[q[0]] >= k:
            ans = min(ans, i - q.popleft())
        while q and s[q[-1]] >= v:
            q.pop()
        q.append(i)
    return -1 if ans == inf else ans
