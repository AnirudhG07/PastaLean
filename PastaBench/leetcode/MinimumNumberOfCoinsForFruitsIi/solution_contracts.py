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
from collections import deque
from contracts import *


def minimumCoins(prices: List[int]) -> int:
    Requires(len(prices) > 0)
    n = len(prices)
    q = deque()
    for i in range(n, 0, -1):
        Invariant(1 <= i)
        Invariant(i <= n)
        # Remove indices out of the allowed jump range
        while q and q[0] > i * 2 + 1:
            q.popleft()
        if i <= (n - 1) // 2:
            Assert(q)  # deque must be non-empty here so q[0] is valid
            prices[i - 1] += prices[q[0] - 1]
        # Maintain deque in increasing order of prices[*-1]
        while q and prices[q[-1] - 1] >= prices[i - 1]:
            q.pop()
        q.append(i)
    return prices[0]