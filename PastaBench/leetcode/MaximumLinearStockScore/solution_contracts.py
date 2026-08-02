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

def maxScore(prices: List[int]) -> int:
    Requires(len(prices) > 0)
    # This property holds if all prices are non-negative.
    # With negative prices, a group sum could be less than the maximum element in that group.
    Requires(all(p >= 0 for p in prices))
    # The maximum group sum is at least as large as the maximum single price.
    Ensures(Result() >= max(prices))

    cnt = Counter()
    for i, x in enumerate(prices):
        Invariant(0 <= i <= len(prices))
        # Since all input prices are non-negative, all accumulated sums in the counter must also be non-negative.
        Invariant(all(v >= 0 for v in cnt.values()))
        cnt[x - i] += x
    return max(cnt.values())