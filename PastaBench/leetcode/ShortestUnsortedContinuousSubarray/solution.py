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

def findUnsortedSubarray(nums: List[int]) -> int:
    arr = sorted(nums)
    l, r = (0, len(nums) - 1)
    while l <= r and nums[l] == arr[l]:
        l += 1
    while l <= r and nums[r] == arr[r]:
        r -= 1
    return r - l + 1
