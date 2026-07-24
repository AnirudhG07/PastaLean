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

def minDays(n: int) -> int:
    Requires(n >= 0)
    # The number of days is non-negative and never exceeds eating one orange per day.
    Ensures(Result() >= 0)
    Ensures(Result() <= n)

    @cache
    def dfs(n: int) -> int:
        Requires(n >= 0)
        if n < 2:
            return n
        return 1 + min(n % 2 + dfs(n // 2), n % 3 + dfs(n // 3))

    return dfs(n)