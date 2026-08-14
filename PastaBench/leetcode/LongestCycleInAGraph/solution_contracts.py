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
inf = float('inf')

def longestCycle(edges: List[int]) -> int:
    Requires(all(-1 <= e < len(edges) for e in edges))
    Ensures(-1 <= Result() <= len(edges))

    n = len(edges)
    vis = [False] * n
    ans = -1
    for i in range(n):
        Invariant(0 <= i <= n)
        Invariant(-1 <= ans <= n)
        Invariant(len(vis) == n)

        if vis[i]:
            continue
        j = i
        cycle = []
        while j != -1 and (not vis[j]):
            Invariant(0 <= j < n)
            Invariant(len(cycle) <= n)
            Invariant(all(0 <= node < n for node in cycle))
            Invariant(len(set(cycle)) == len(cycle))
            Decreases(n - len(cycle))

            vis[j] = True
            cycle.append(j)
            j = edges[j]

        if j == -1:
            continue

        Assert(j != -1)
        Assert(0 <= j < n)
        Assert(j in cycle)
        m = len(cycle)
        Assert(0 < m <= n)
        k = next((k for k in range(m) if cycle[k] == j), inf)
        Assert(0 <= k < m)
        Assert(0 < m - k <= n)
        ans = max(ans, m - k)
        Assert(-1 <= ans <= n)

    Assert(-1 <= ans <= n)
    return ans