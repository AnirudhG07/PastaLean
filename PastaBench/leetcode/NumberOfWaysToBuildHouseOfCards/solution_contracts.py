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

def houseOfCards(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() >= 0)

    @cache
    def dfs(n: int, k: int) -> int:
        Requires(n >= 0)
        Requires(k >= 0)
        Decreases(n + 1 - k)
        Ensures(Result() >= 0)
        x = 3 * k + 2
        if x > n:
            return 0
        if x == n:
            return 1
        return dfs(n - x, k + 1) + dfs(n, k + 1)

    return dfs(n, 0)