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

def minDifficulty(jobDifficulty: List[int], d: int) -> int:
    Requires(d >= 1)
    Requires(len(jobDifficulty) >= 1)
    Requires(all(jd >= 0 for jd in jobDifficulty))
    Ensures((len(jobDifficulty) < d and Result() == -1) or \
            (len(jobDifficulty) >= d and Result() >= 0))

    n = len(jobDifficulty)
    f = [[inf] * (d + 1) for _ in range(n + 1)]
    f[0][0] = 0
    for i in range(1, n + 1):
        Invariant(1 <= i <= n + 1)
        for j in range(1, min(d + 1, i + 1)):
            Invariant(1 <= j <= d)
            Invariant(j <= i)
            mx = 0
            for k in range(i, 0, -1):
                Invariant(1 <= k <= i)
                Invariant(mx >= 0)
                # Bounded-index invariants for memory safety
                Invariant(0 <= k - 1 < n)
                Invariant(0 <= k - 1 <= n)
                Invariant(0 <= j - 1 <= d)
                mx = max(mx, jobDifficulty[k - 1])
                f[i][j] = min(f[i][j], f[k - 1][j - 1] + mx)
    return -1 if f[n][d] >= inf else f[n][d]