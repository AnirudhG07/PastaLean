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

def nearestPalindromic(n: str) -> str:
    Requires(len(n) >= 1)
    Requires(n.isdigit())
    Requires(int(n) >= 1)

    Ensures(str(int(Result())) == str(int(Result()))[::-1])
    Ensures(int(Result()) != int(n))

    x = int(n)
    l = len(n)
    res = {10 ** (l - 1) - 1, 10 ** l + 1}
    left = int(n[:l + 1 >> 1])
    for i in range(left - 1, left + 2):
        j = i if l % 2 == 0 else i // 10
        p = i
        while j:
            Invariant(j >= 0)
            Decreases(j)
            p = p * 10 + j % 10
            j //= 10
        res.add(p)
    res.discard(x)
    Assert(x not in res)
    ans = -1
    for t in res:
        if ans == -1 or abs(t - x) < abs(ans - x) or (abs(t - x) == abs(ans - x) and t < ans):
            ans = t
    Assert(ans != -1)
    Assert(ans in res)
    return str(ans)