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

def countPairs(nums: list[int], k: int) -> int:
    Requires(k > 0)
    ans = 0
    gcds = collections.Counter()
    for num in nums:
        gcd_i = math.gcd(num, k)
        for gcd_j, count in gcds.items():
            if gcd_i * gcd_j % k == 0:
                ans += count
        gcds[gcd_i] += 1
    return ans