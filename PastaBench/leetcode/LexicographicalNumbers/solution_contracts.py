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


def lexicalOrder(n: int) -> List[int]:
    Requires(n >= 0)
    Ensures(len(Result()) == n)
    ans = []
    v = 1
    for _ in range(n):
        Invariant(0 <= len(ans))
        Invariant(len(ans) <= n)
        Decreases(n - len(ans))
        ans.append(v)
        if v * 10 <= n:
            v *= 10
        else:
            while v % 10 == 9 or v + 1 > n:
                v //= 10
            v += 1
    Assert(len(ans) == n)
    return ans