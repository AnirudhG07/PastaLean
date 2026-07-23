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


def hIndex(citations: List[int]) -> int:
    Requires(all(citations[i-1] <= citations[i] for i in range(1, len(citations))))
    n = len(citations)
    Ensures(0 <= Result())
    Ensures(Result() <= n)
    Ensures(Result() == 0 or citations[n-Result()] >= Result())
    left, right = 0, n
    while left < right:
        Invariant(0 <= left)
        Invariant(left <= right)
        Invariant(right <= n)
        Invariant(left == 0 or citations[n-left] >= left)
        Decreases(right - left)
        mid = left + right + 1 >> 1
        if citations[n - mid] >= mid:
            left = mid
        else:
            right = mid - 1
    Assert(left == 0 or citations[n-left] >= left)
    return left