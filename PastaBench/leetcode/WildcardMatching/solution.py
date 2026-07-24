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
    def dfs(i: int, j: int) -> bool:
        if i >= len(s):
            return j >= len(p) or (p[j] == '*' and dfs(i, j + 1))
        if j >= len(p):
            return False
        if p[j] == '*':
            return dfs(i + 1, j) or dfs(i + 1, j + 1) or dfs(i, j + 1)
        return (p[j] == '?' or s[i] == p[j]) and dfs(i + 1, j + 1)
    return dfs(0, 0)
