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


def numIdenticalPairs(nums: List[int]) -> int:
    Ensures(2 * Result() == sum(v * (v - 1) for v in Counter(nums).values()))
    ans = 0
    cnt = Counter()
    for x in nums:
        Invariant(2 * ans == sum(v * (v - 1) for v in cnt.values()))
        ans += cnt[x]
        cnt[x] += 1
    Assert(2 * ans == sum(v * (v - 1) for v in cnt.values()))
    return ans