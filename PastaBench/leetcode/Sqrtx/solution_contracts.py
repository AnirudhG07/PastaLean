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

def mySqrt(x: int) -> int:
    Requires(x >= 0)
    Ensures(Result() * Result() <= x)
    Ensures((Result() + 1) * (Result() + 1) > x)
    l, r = (0, x)
    while l < r:
        Invariant(0 <= l)
        Invariant(l <= r)
        Invariant(r <= x)
        Invariant(l * l <= x)
        Invariant((r + 1) * (r + 1) > x)
        Decreases(r - l)
        mid = l + r + 1 >> 1
        if mid > x // mid:
            r = mid - 1
        else:
            l = mid
    Assert(l * l <= x)
    Assert((l + 1) * (l + 1) > x)
    return l