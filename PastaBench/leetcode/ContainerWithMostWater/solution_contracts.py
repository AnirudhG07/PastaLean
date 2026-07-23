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

def maxArea(height: List[int]) -> int:
    Requires(len(height) >= 2)
    # The result equals the maximum container area over all pairs (i, j) with i < j
    Ensures(
        Result()
        == max(
            (
                min(height[i], height[j]) * (j - i)
                for i in range(len(height))
                for j in range(i + 1, len(height))
            ),
            default=0,
        )
    )
    l, r = 0, len(height) - 1
    ans = 0
    while l < r:
        t = min(height[l], height[r]) * (r - l)
        ans = max(ans, t)
        if height[l] < height[r]:
            l += 1
        else:
            r -= 1
    return ans