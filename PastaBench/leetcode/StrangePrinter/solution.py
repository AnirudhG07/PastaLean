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
inf = float('inf')

def strangePrinter(s: str) -> int:
    n = len(s)
    f = [[inf] * n for _ in range(n)]
    for i in range(n - 1, -1, -1):
        f[i][i] = 1
        for j in range(i + 1, n):
            if s[i] == s[j]:
                f[i][j] = f[i][j - 1]
            else:
                for k in range(i, j):
                    f[i][j] = min(f[i][j], f[i][k] + f[k + 1][j])
    return f[0][-1]
