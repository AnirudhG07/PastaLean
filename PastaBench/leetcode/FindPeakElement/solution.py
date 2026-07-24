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

def findPeakElement(nums: List[int]) -> int:
    left, right = (0, len(nums) - 1)
    while left < right:
        mid = left + right >> 1
        if nums[mid] > nums[mid + 1]:
            right = mid
        else:
            left = mid + 1
    return left
