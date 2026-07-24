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

def isMatch(s: str, p: str) -> bool:

    @cache
    def dfs(i, j):
        if j >= n:
            return i == m
        if j + 1 < n and p[j + 1] == '*':
            return dfs(i, j + 2) or (i < m and (s[i] == p[j] or p[j] == '.') and dfs(i + 1, j))
        return i < m and (s[i] == p[j] or p[j] == '.') and dfs(i + 1, j + 1)
    m, n = (len(s), len(p))
    return dfs(0, 0)
