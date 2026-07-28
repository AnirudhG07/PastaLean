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

    @cache
    def dfs(n: int, k: int) -> int:
        x = 3 * k + 2
        if x > n:
            return 0
        if x == n:
            return 1
        return dfs(n - x, k + 1) + dfs(n, k + 1)
    return dfs(n, 0)
