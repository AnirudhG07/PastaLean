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

def minimumRightShifts(nums: List[int]) -> int:
    n = len(nums)
    i = 1
    while i < n and nums[i - 1] < nums[i]:
        i += 1
    k = i + 1
    while k < n and nums[k - 1] < nums[k] < nums[0]:
        k += 1
    return -1 if k < n else n - i
