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

def maxLength(ribbons: List[int], k: int) -> int:
    Requires(len(ribbons) > 0)
    Requires(min(ribbons) >= 0)
    Requires(k > 0)
    # At return, no length > Result() yields >= k pieces, and Result()==0 or Result() yields >= k pieces
    Ensures(sum((x // (Result() + 1) for x in ribbons)) < k)
    Ensures((Result() == 0) or sum((x // Result() for x in ribbons)) >= k)
    M = max(ribbons)
    left, right = (0, M)
    while left < right:
        Invariant(0 <= left)
        Invariant(left <= right)
        Invariant(right <= M)
        # left is always a feasible length (or zero)
        Invariant((left == 0) or sum((x // left for x in ribbons)) >= k)
        # right+1 is always infeasible
        Invariant(sum((x // (right + 1) for x in ribbons)) < k)
        Decreases(right - left)
        mid = (left + right + 1) >> 1
        cnt = sum((x // mid for x in ribbons))
        if cnt >= k:
            left = mid
        else:
            right = mid - 1
    return left