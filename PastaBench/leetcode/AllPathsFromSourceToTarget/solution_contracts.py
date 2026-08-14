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

def allPathsSourceTarget(graph: List[List[int]]) -> List[List[int]]:
    n = len(graph)
    Requires(n > 0)
    Requires(all(0 <= v < n for neighbors in graph for v in neighbors))

    Ensures(all(
        len(p) > 0 and
        p[0] == 0 and
        p[-1] == n - 1 and
        all(0 <= node < n for node in p) and
        all(p[i+1] in graph[p[i]] for i in range(len(p) - 1))
        for p in Result()
    ))

    q = deque([[0]])
    ans = []
    while q:
        Invariant(all(
            len(p) > 0 and
            p[0] == 0 and
            p[-1] == n - 1 and
            all(0 <= node < n for node in p) and
            all(p[i+1] in graph[p[i]] for i in range(len(p) - 1))
            for p in ans
        ))
        Invariant(all(
            len(p) > 0 and
            p[0] == 0 and
            all(0 <= node < n for node in p) and
            all(p[i+1] in graph[p[i]] for i in range(len(p) - 1))
            for p in q
        ))

        path = q.popleft()
        u = path[-1]
        
        Assert(0 <= u < n)

        if u == n - 1:
            ans.append(path)
            continue
        for v in graph[u]:
            q.append(path + [v])
    return ans