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


def replaceNonCoprimes(nums: List[int]) -> List[int]:
    Ensures(all(gcd(Result()[i], Result()[i+1]) == 1 for i in range(len(Result()) - 1)))
    stk: List[int] = []
    for x in nums:
        Invariant(0 <= len(stk))
        Invariant(len(stk) <= len(nums))
        Invariant(all(gcd(stk[i], stk[i+1]) == 1 for i in range(len(stk) - 1)))
        stk.append(x)
        while len(stk) > 1:
            Invariant(2 <= len(stk))
            Invariant(len(stk) <= len(nums))
            Invariant(all(gcd(stk[i], stk[i+1]) == 1 for i in range(len(stk) - 2)))
            Decreases(len(stk))
            x2, y = stk[-2:]
            g = gcd(x2, y)
            if g == 1:
                break
            stk.pop()
            stk[-1] = x2 * y // g
        Assert(all(gcd(stk[i], stk[i+1]) == 1 for i in range(len(stk) - 1)))
    return stk