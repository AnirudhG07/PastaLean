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

def minSwaps(s: str) -> int:

    def calc(c: int) -> int:
        return sum((c ^ i & 1 != x for i, x in enumerate(map(int, s)))) // 2
    n0 = s.count('0')
    n1 = len(s) - n0
    if abs(n0 - n1) > 1:
        return -1
    if n0 == n1:
        return min(calc(0), calc(1))
    return calc(0 if n0 > n1 else 1)
