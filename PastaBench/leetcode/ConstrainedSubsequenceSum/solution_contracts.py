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
inf = float('inf')


def constrainedSubsetSum(nums: List[int], k: int) -> int:
    Requires(len(nums) > 0)
    Requires(k >= 1)
    q = deque([0])
    n = len(nums)
    f = [0] * n
    ans = -inf
    for i, x in enumerate(nums):
        Invariant(0 <= i)
        Invariant(i < n)
        Invariant(len(q) > 0)
        # compute best subsequence sum ending at i, using the max from the window
        f[i] = max(0, f[q[0]]) + x
        ans = max(ans, f[i])
        # maintain deque in decreasing f[] order
        while q and f[q[-1]] <= f[i]:
            q.pop()
        q.append(i)
    return ans