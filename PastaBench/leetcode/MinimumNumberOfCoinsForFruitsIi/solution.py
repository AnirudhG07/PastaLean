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

def minimumCoins(prices: List[int]) -> int:
    n = len(prices)
    q = deque()
    for i in range(n, 0, -1):
        while q and q[0] > i * 2 + 1:
            q.popleft()
        if i <= (n - 1) // 2:
            prices[i - 1] += prices[q[0] - 1]
        while q and prices[q[-1] - 1] >= prices[i - 1]:
            q.pop()
        q.append(i)
    return prices[0]
