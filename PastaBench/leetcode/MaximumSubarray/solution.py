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

def maxSubArray(nums: List[int]) -> int:
    ans = f = nums[0]
    for x in nums[1:]:
        f = max(f, 0) + x
        ans = max(ans, f)
    return ans
