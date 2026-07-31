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

def allPathsSourceTarget(graph: List[List[int]]) -> List[List[int]]:
    n = len(graph)
    q = deque([[0]])
    ans = []
    while q:
        path = q.popleft()
        u = path[-1]
        if u == n - 1:
            ans.append(path)
            continue
        for v in graph[u]:
            q.append(path + [v])
    return ans
