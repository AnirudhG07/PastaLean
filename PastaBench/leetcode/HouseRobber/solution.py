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

def rob(nums: List[int]) -> int:

    @cache
    def dfs(i: int) -> int:
        if i >= len(nums):
            return 0
        return max(nums[i] + dfs(i + 2), dfs(i + 1))
    return dfs(0)
