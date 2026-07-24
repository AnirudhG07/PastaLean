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

def findKthNumber(m: int, n: int, k: int) -> int:
    left, right = (1, m * n)
    while left < right:
        mid = left + right >> 1
        cnt = 0
        for i in range(1, m + 1):
            cnt += min(mid // i, n)
        if cnt >= k:
            right = mid
        else:
            left = mid + 1
    return left
