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

def minOperations(nums: List[int], numsDivide: List[int]) -> int:
    x = numsDivide[0]
    for v in numsDivide[1:]:
        x = gcd(x, v)
    nums.sort()
    for i, v in enumerate(nums):
        if x % v == 0:
            return i
    return -1
