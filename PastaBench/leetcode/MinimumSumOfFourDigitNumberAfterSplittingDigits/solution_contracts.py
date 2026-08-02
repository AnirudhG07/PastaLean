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

def minimumSum(num: int) -> int:
    Requires(1000 <= num and num <= 9999)
    nums = []
    while num:
        Invariant(num >= 0)
        Decreases(num)
        nums.append(num % 10)
        num //= 10
    Assert(len(nums) == 4)
    nums.sort()
    Assert(nums[0] <= nums[1] and nums[1] <= nums[2] and nums[2] <= nums[3])
    return 10 * (nums[0] + nums[1]) + nums[2] + nums[3]