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

def countNicePairs(nums: List[int]) -> int:
    Requires(all(n >= 0 for n in nums))

    def rev(x: int) -> int:
        Requires(x >= 0)
        y = 0
        while x:
            Invariant(x >= 0)
            Invariant(y >= 0)
            Decreases(x)
            y = y * 10 + x % 10
            x //= 10
        return y

    cnt = Counter((x - rev(x) for x in nums))
    mod = 10 ** 9 + 7
    return sum((v * (v - 1) // 2 for v in cnt.values())) % mod