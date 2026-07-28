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

def prefixesDivBy5(nums: List[int]) -> List[bool]:
    Requires(all(v == 0 or v == 1 for v in nums))
    Ensures(len(Result()) == len(nums))
    ans = []
    x = 0
    for v in nums:
        Assert(v == 0 or v == 1)
        Invariant(0 <= x)
        Invariant(x < 5)
        x = (x << 1 | v) % 5
        ans.append(x == 0)
    return ans