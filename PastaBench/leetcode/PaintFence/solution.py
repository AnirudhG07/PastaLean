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

def numWays(n: int, k: int) -> int:
    f = [0] * n
    g = [0] * n
    f[0] = k
    for i in range(1, n):
        f[i] = (f[i - 1] + g[i - 1]) * (k - 1)
        g[i] = f[i - 1]
    return f[-1] + g[-1]
