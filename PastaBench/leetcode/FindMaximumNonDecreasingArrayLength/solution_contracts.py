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

def findMaximumLength(nums: List[int]) -> int:
    n = len(nums)
    s = list(accumulate(nums, initial=0))
    f = [0] * (n + 1)
    pre = [0] * (n + 2)
    for i in range(1, n + 1):
        # Bounds for indexing into f, s, pre
        Invariant(1 <= i <= n)
        Invariant(0 <= pre[i] <= i)
        pre[i] = max(pre[i], pre[i - 1])
        f[i] = f[pre[i]] + 1
        j = bisect_left(s, s[i] * 2 - s[pre[i]])
        # bisect_left returns 0 <= j <= len(s) == n+1
        Assert(0 <= j <= n + 1)
        pre[j] = i
    return f[n]