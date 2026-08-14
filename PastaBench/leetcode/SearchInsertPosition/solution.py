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

def searchInsert(nums: List[int], target: int) -> int:
    l, r = (0, len(nums))
    while l < r:
        mid = l + r >> 1
        if nums[mid] >= target:
            r = mid
        else:
            l = mid + 1
    return l
