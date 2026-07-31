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

def circularGameLosers(n: int, k: int) -> List[int]:
    Requires(n >= 1)
    Requires(k >= 1)
    Ensures(all(1 <= x <= n for x in Result()))

    vis = [False] * n
    i, p = (0, 1)
    while not vis[i]:
        Invariant(0 <= i < n)
        Invariant(p >= 1)
        Invariant(len(vis) == n)
        Invariant(sum(1 for v in vis if v) == p - 1)
        Decreases(n - sum(1 for v in vis if v))

        vis[i] = True
        i = (i + p * k) % n
        p += 1

    Assert(0 <= i < n)
    Assert(vis[i])
    return [i + 1 for i in range(n) if not vis[i]]