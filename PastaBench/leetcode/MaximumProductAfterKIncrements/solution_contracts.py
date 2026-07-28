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

def maximumProduct(nums: List[int], k: int) -> int:
    Requires(k >= 0)
    Requires(len(nums) > 0)
    heapify(nums)
    for _ in range(k):
        heapreplace(nums, nums[0] + 1)
    mod = 10 ** 9 + 7
    return reduce(lambda x, y: x * y % mod, nums)