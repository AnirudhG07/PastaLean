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

def maxProduct(nums: List[int]) -> int:
    ans = 0
    for i, a in enumerate(nums):
        for b in nums[i + 1:]:
            ans = max(ans, (a - 1) * (b - 1))
    return ans
