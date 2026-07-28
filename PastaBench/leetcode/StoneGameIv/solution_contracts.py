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


def winnerSquareGame(n: int) -> bool:
    Requires(n >= 0)
    @cache
    def dfs(i: int) -> bool:
        Requires(i >= 0)
        if i == 0:
            return False
        j = 1
        while j * j <= i:
            Invariant(1 <= j)
            Invariant(j <= i)
            Decreases(i - j)
            if not dfs(i - j * j):
                return True
            j += 1
        return False
    return dfs(n)