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

def maxValue(n: int, index: int, maxSum: int) -> int:

    def sum(x, cnt):
        return (x + x - cnt + 1) * cnt // 2 if x >= cnt else (x + 1) * x // 2 + cnt - x
    left, right = (1, maxSum)
    while left < right:
        mid = left + right + 1 >> 1
        if sum(mid - 1, index) + sum(mid, n - index) <= maxSum:
            left = mid
        else:
            right = mid - 1
    return left
