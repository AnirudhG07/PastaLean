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

def rearrangeSticks(n: int, k: int) -> int:
    mod = 10 ** 9 + 7
    f = [[0] * (k + 1) for _ in range(n + 1)]
    f[0][0] = 1
    for i in range(1, n + 1):
        for j in range(1, k + 1):
            f[i][j] = (f[i - 1][j - 1] + f[i - 1][j] * (i - 1)) % mod
    return f[n][k]
