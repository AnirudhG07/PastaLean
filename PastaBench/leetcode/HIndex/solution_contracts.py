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

def hIndex(citations: List[int]) -> int:
    Ensures(0 <= Result() <= len(citations))
    Ensures(
        (Result() == 0 and
         all(citations[k-1] < k for k in range(1, len(citations) + 1)))
        or
        (1 <= Result() <= len(citations) and
         citations[Result() - 1] >= Result() and
         all(citations[k-1] < k for k in range(Result() + 1, len(citations) + 1)))
    )
    citations.sort(reverse=True)
    n = len(citations)
    for h in range(n, 0, -1):
        Invariant(1 <= h)
        Invariant(h <= n)
        Invariant(all(citations[k-1] < k for k in range(h + 1, n + 1)))
        if citations[h - 1] >= h:
            Assert(citations[h - 1] >= h)
            return h
    Assert(all(citations[k-1] < k for k in range(1, n + 1)))
    return 0