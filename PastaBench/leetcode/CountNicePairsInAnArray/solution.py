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

def countNicePairs(nums: List[int]) -> int:

    def rev(x):
        y = 0
        while x:
            y = y * 10 + x % 10
            x //= 10
        return y
    cnt = Counter((x - rev(x) for x in nums))
    mod = 10 ** 9 + 7
    return sum((v * (v - 1) // 2 for v in cnt.values())) % mod
