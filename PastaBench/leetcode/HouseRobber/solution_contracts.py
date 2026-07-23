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
from contracts import *

def rob(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    @cache
    def dfs(i: int) -> int:
        Requires(i >= 0)
        Ensures(Result() >= 0)
        if i >= len(nums):
            return 0
        Assert(i < len(nums))
        return max(nums[i] + dfs(i + 2), dfs(i + 1))
    return dfs(0)