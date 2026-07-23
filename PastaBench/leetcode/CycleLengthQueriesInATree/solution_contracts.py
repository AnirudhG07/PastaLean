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

def cycleLengthQueries(n: int, queries: List[List[int]]) -> List[int]:
    Ensures(len(Result()) == len(queries))                  # one output per query
    Ensures(all(t >= 1 for t in Result()))                  # each cycle length is at least 1
    ans = []
    for a, b in queries:
        t = 1
        while a != b:
            Invariant(a > 0)                                # a stays positive
            Invariant(b > 0)                                # b stays positive
            Invariant(t >= 1)                               # step count non-decreasing
            Decreases(max(a, b))                            # termination measure
            if a > b:
                a >>= 1
            else:
                b >>= 1
            t += 1
        ans.append(t)
    return ans