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

def circularPermutation(n: int, start: int) -> List[int]:
    Requires(n >= 0)
    Requires(0 <= start)
    Requires(start < (1 << n))
    Ensures(len(Result()) == 1 << n)
    Ensures(Result()[0] == start)
    g = [i ^ i >> 1 for i in range(1 << n)]
    Assert(len(g) == 1 << n)
    j = g.index(start)
    Assert(0 <= j)
    Assert(j < len(g))
    Assert(g[j] == start)
    r = g[j:] + g[:j]
    Assert(len(r) == len(g))
    Assert(r[0] == start)
    return r