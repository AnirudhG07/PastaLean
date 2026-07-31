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

def maximumLength(nums: List[int], k: int) -> int:
    f = [[0] * k for _ in range(k)]
    ans = 0
    for x in nums:
        x %= k
        for j in range(k):
            y = (j - x + k) % k
            f[x][y] = f[y][x] + 1
            ans = max(ans, f[x][y])
    return ans
