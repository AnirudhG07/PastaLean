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

def magicalString(n: int) -> int:
    Requires(n >= 0)
    Ensures(0 <= Result() <= n)

    if n == 0:
        return 0
    if n <= 3:
        return 1

    s = [1, 2, 2]
    i = 2
    while len(s) < n:
        Invariant(i >= 2)
        Invariant(len(s) >= 3)
        # This is the key invariant that proves the access s[i] is always safe.
        # The gap len(s) - i starts at 1 and is non-decreasing.
        Invariant(i < len(s))
        Decreases(n - len(s))

        pre = s[-1]
        Assert(pre == 1 or pre == 2)
        cur = 3 - pre
        Assert(cur == 1 or cur == 2)
        
        # All elements of s are guaranteed to be 1 or 2.
        Assert(s[i] == 1 or s[i] == 2)
        s += [cur] * s[i]
        i += 1
    
    Assert(len(s) >= n)
    return s[:n].count(1)