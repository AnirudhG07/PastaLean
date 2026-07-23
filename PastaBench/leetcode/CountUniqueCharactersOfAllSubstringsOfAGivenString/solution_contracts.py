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

def uniqueLetterString(s: str) -> int:
    ans = 0
    d = defaultdict(list)
    for i, c in enumerate(s):
        d[c].append(i)
    for v in d.values():
        v = [-1] + v + [len(s)]
        for i in range(1, len(v) - 1):
            Invariant(1 <= i)
            Invariant(i < len(v) - 1)
            Invariant(ans >= 0)
            ans += (v[i] - v[i - 1]) * (v[i + 1] - v[i])
    Assert(ans >= 0)
    return ans