import heapq
import itertools
from sortedcontainers import SortedList
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


def canMeasureWater(x: int, y: int, target: int) -> bool:
    Requires(x >= 0)
    Requires(y >= 0)
    Requires(target >= 0)
    # The result is true exactly if target is zero or we have enough total capacity
    # and target is a multiple of gcd(x, y).
    Ensures(
        Result()
        == (
            target == 0
            or (x + y >= target and target % math.gcd(x, y) == 0)
        )
    )
    if target == 0:
        return True
    if x + y < target:
        return False
    # Bridge the guard: now we know x + y >= target
    Assert(x + y >= target)
    g = math.gcd(x, y)
    # In this branch gcd must be positive (x+y>=target>0 when g==0 is impossible here)
    Assert(g > 0)
    return target % g == 0