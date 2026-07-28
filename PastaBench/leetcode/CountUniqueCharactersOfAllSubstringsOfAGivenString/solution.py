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
    d = defaultdict(list)
    for i, c in enumerate(s):
        d[c].append(i)
    ans = 0
    for v in d.values():
        v = [-1] + v + [len(s)]
        for i in range(1, len(v) - 1):
            ans += (v[i] - v[i - 1]) * (v[i + 1] - v[i])
    return ans
