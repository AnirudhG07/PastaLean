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
from contracts import *

def minJumps(arr: List[int]) -> int:
    Requires(len(arr) > 0)
    Ensures(Result() >= 0)
    Ensures(Result() < len(arr))
    g = defaultdict(list)
    for i, x in enumerate(arr):
        g[x].append(i)
    q = deque([0])
    vis = {0}
    ans = 0
    while 1:
        Invariant(ans >= 0)
        Invariant(0 in vis)
        Invariant(1 <= len(vis))
        Invariant(len(vis) <= len(arr))
        Invariant(len(q) > 0)
        Decreases(len(arr) - len(vis))
        for _ in range(len(q)):
            i = q.popleft()
            Assert(0 <= i < len(arr))
            Assert(i in vis)
            if i == len(arr) - 1:
                return ans
            for j in (i + 1, i - 1, *g.pop(arr[i], [])):
                if 0 <= j < len(arr) and j not in vis:
                    Assert(0 <= j < len(arr))
                    Assert(j not in vis)
                    q.append(j)
                    vis.add(j)
                    Assert(j in q)
                    Assert(j in vis)
        ans += 1