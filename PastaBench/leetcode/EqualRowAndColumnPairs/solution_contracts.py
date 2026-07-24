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

def equalPairs(grid: List[List[int]]) -> int:
    Requires(all(len(row) == len(grid) for row in grid))
    n = len(grid)
    Ensures(Result() == sum(1 for i in range(n) for j in range(n)
                           if all(grid[i][k] == grid[k][j] for k in range(n))))
    ans = 0
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i < n)
        Invariant(ans == sum(1 for p in range(i) for q in range(n)
                             if all(grid[p][k] == grid[k][q] for k in range(n))))
        Decreases(n - i)
        for j in range(n):
            Invariant(0 <= j)
            Invariant(j < n)
            Invariant(ans == sum(1 for p in range(i) for q in range(n)
                                 if all(grid[p][k] == grid[k][q] for k in range(n)))
                      + sum(1 for q in range(j)
                            if all(grid[i][k] == grid[k][q] for k in range(n))))
            Decreases(n - j)
            ans += all((grid[i][k] == grid[k][j] for k in range(n)))
    return ans