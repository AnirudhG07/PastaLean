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
inf = float('inf')

def strangePrinter(s: str) -> int:
    Requires(len(s) > 0)
    Ensures(1 <= Result() <= len(s))
    n = len(s)
    f = [[inf] * n for _ in range(n)]
    for i in range(n - 1, -1, -1):
        Invariant(-1 <= i < n)
        f[i][i] = 1
        for j in range(i + 1, n):
            Invariant(0 <= i < n)
            Invariant(i < j < n)
            if s[i] == s[j]:
                f[i][j] = f[i][j - 1]
            else:
                for k in range(i, j):
                    Invariant(0 <= i <= k < j < n)
                    f[i][j] = min(f[i][j], f[i][k] + f[k + 1][j])
    return f[0][-1]