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


def isMatch(s: str, p: str) -> bool:

    @cache
    def dfs(i: int, j: int) -> bool:
        Requires(0 <= i <= len(s) and 0 <= j <= len(p))
        Decreases(len(s) - i + len(p) - j)
        if i >= len(s):
            # safe: p[j] only when j < len(p), by short-circuit
            return j >= len(p) or (p[j] == '*' and dfs(i, j + 1))
        if j >= len(p):
            return False
        # now i < len(s) and j < len(p), so indexing is safe
        Assert(i < len(s))
        Assert(j < len(p))
        if p[j] == '*':
            return dfs(i + 1, j) or dfs(i + 1, j + 1) or dfs(i, j + 1)
        return (p[j] == '?' or s[i] == p[j]) and dfs(i + 1, j + 1)

    return dfs(0, 0)