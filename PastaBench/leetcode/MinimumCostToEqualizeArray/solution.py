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

def minCostToEqualizeArray(nums: list[int], cost1: int, cost2: int) -> int:
    MOD = 1000000007
    n = len(nums)
    minNum = min(nums)
    maxNum = max(nums)
    summ = sum(nums)
    if cost1 * 2 <= cost2 or n < 3:
        totalGap = maxNum * n - summ
        return cost1 * totalGap % MOD

    def getMinCost(target: int) -> int:
        """Returns the minimum cost to make all numbers equal to `target`."""
        maxGap = target - minNum
        totalGap = target * n - summ
        pairs = min(totalGap // 2, totalGap - maxGap)
        return cost1 * (totalGap - 2 * pairs) + cost2 * pairs
    return min((getMinCost(target) for target in range(maxNum, 2 * maxNum))) % MOD
