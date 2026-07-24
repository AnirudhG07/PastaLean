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

def maxArrayValue(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    for i in range(len(nums) - 2, -1, -1):
        if nums[i] <= nums[i + 1]:
            nums[i] += nums[i + 1]
    return max(nums)