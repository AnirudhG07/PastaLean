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


def findNthDigit(n: int) -> int:
    Requires(n >= 1)
    Ensures(0 <= Result() < 10)
    k, cnt = (1, 9)
    while k * cnt < n:
        Invariant(n > 0)
        Invariant(k > 0)
        Invariant(cnt > 0)
        Decreases(n)
        n -= k * cnt
        k += 1
        cnt *= 10
    # Now 1 <= n <= k*cnt and k>0
    Assert(k > 0)
    Assert(cnt > 0)
    num = 10 ** (k - 1) + (n - 1) // k
    # offset in [0, cnt-1]
    Assert(0 <= (n - 1) // k)
    Assert((n - 1) // k < cnt)
    idx = (n - 1) % k
    Assert(0 <= idx < k)
    # num is in [10^(k-1), 10^k)
    Assert(10 ** (k - 1) <= num)
    Assert(num < 10 ** k)
    return int(str(num)[idx])