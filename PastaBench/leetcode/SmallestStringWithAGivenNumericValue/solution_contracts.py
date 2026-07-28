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

def getSmallestString(n: int, k: int) -> str:
    Requires(n >= 1)
    Requires(k >= n)
    Requires(k <= 26 * n)
    Ensures(len(Result()) == n)
    Ensures(sum(ord(c) - ord('a') + 1 for c in Result()) == k)

    ans = ['a'] * n
    i, d = (n - 1, k - n)
    while d > 25:
        Invariant(0 <= i)
        Invariant(i < n)
        Invariant(d >= 0)
        Invariant(d <= 25 * (i + 1))
        Decreases(d)

        ans[i] = 'z'
        d -= 25
        i -= 1

    Assert(0 <= i < n)
    ans[i] = chr(ord(ans[i]) + d)
    return ''.join(ans)