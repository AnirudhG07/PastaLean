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

def subarrayGCD(nums: List[int], k: int) -> int:
    Requires(k >= 0)
    Ensures(Result() >= 0)
    ans = 0
    for i in range(len(nums)):
        Invariant(0 <= i)
        Invariant(i < len(nums))
        Invariant(ans >= 0)
        g = 0
        for x in nums[i:]:
            Invariant(ans >= 0)
            g = gcd(g, x)
            ans += (g == k)
    return ans