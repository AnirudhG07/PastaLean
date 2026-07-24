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

def constrainedSubsetSum(nums: List[int], k: int) -> int:
    q = deque([0])
    n = len(nums)
    f = [0] * n
    ans = -inf
    for i, x in enumerate(nums):
        while i - q[0] > k:
            q.popleft()
        f[i] = max(0, f[q[0]]) + x
        ans = max(ans, f[i])
        while q and f[q[-1]] <= f[i]:
            q.pop()
        q.append(i)
    return ans
