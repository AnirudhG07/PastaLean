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

def sumOfDigits(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Requires(all(n >= 0 for n in nums))
    Ensures(Result() == 0 or Result() == 1)
    x = min(nums)
    Assert(x >= 0)
    s = 0
    while x:
        Invariant(x >= 0)
        Invariant(s >= 0)
        Decreases(x)
        s += x % 10
        x //= 10
    return s & 1 ^ 1