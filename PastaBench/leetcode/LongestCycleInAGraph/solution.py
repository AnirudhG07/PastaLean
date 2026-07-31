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

def longestCycle(edges: List[int]) -> int:
    n = len(edges)
    vis = [False] * n
    ans = -1
    for i in range(n):
        if vis[i]:
            continue
        j = i
        cycle = []
        while j != -1 and (not vis[j]):
            vis[j] = True
            cycle.append(j)
            j = edges[j]
        if j == -1:
            continue
        m = len(cycle)
        k = next((k for k in range(m) if cycle[k] == j), inf)
        ans = max(ans, m - k)
    return ans
