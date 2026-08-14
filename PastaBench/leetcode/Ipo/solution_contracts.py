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

def findMaximizedCapital(k: int, w: int, profits: List[int], capital: List[int]) -> int:
    Requires(k >= 0)
    Requires(w >= 0)
    Requires(len(profits) == len(capital))
    Requires(all(p >= 0 for p in profits))
    Requires(all(c >= 0 for c in capital))
    Ensures(Result() >= w)

    h1 = [(c, p) for c, p in zip(capital, profits)]
    heapify(h1)
    h2 = []
    while k:
        Invariant(k >= 0)
        Invariant(w >= 0)
        Invariant(all(item[0] >= 0 and item[1] >= 0 for item in h1))
        Invariant(all(p_neg <= 0 for p_neg in h2))
        Decreases(k)

        while h1 and h1[0][0] <= w:
            Decreases(len(h1))
            heappush(h2, -heappop(h1)[1])
        
        Assert(not h1 or h1[0][0] > w)

        if not h2:
            break
        
        w -= heappop(h2)
        k -= 1
    return w