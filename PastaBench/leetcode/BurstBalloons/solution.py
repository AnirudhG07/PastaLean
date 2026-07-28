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

def maxCoins(nums: List[int]) -> int:
    n = len(nums)
    arr = [1] + nums + [1]
    f = [[0] * (n + 2) for _ in range(n + 2)]
    for i in range(n - 1, -1, -1):
        for j in range(i + 2, n + 2):
            for k in range(i + 1, j):
                f[i][j] = max(f[i][j], f[i][k] + f[k][j] + arr[i] * arr[k] * arr[j])
    return f[0][-1]
