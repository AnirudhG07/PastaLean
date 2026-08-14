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

def maximumXOR(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Requires(all(x >= 0 for x in nums))
    # The result is the bitwise OR of all numbers. This means that for any number
    # in the input list, all of its set bits are also set in the result.
    Ensures(all((x & Result()) == x for x in nums))
    Ensures(Result() >= 0)
    return reduce(or_, nums)