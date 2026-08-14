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

def minOperations(nums: List[int], k: int) -> int:
    Requires(k >= 0)
    Requires(all(x >= 0 for x in nums))
    # The minimum number of single-bit-flip operations to make the XOR sum of `nums` equal to `k`
    # is the Hamming distance between the XOR sum of `nums` and `k`.
    Ensures(Result() == (reduce(xor, nums, 0) ^ k).bit_count())
    return reduce(xor, nums, k).bit_count()