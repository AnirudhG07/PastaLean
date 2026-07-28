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

def maximumBeauty(nums: List[int], k: int) -> int:
    m = max(nums) + k * 2 + 2
    d = [0] * m
    for x in nums:
        d[x] += 1
        d[x + k * 2 + 1] -= 1
    return max(accumulate(d))
