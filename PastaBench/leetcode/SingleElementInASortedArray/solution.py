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

def singleNonDuplicate(nums: List[int]) -> int:
    l, r = (0, len(nums) - 1)
    while l < r:
        mid = l + r >> 1
        if nums[mid] != nums[mid ^ 1]:
            r = mid
        else:
            l = mid + 1
    return nums[l]
