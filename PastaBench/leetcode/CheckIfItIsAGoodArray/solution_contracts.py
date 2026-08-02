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

def isGoodArray(nums: List[int]) -> bool:
    Requires(len(nums) > 0)
    Requires(all(n > 0 for n in nums))
    # The intent is that the numbers are coprime as a set, which is equivalent
    # to their greatest common divisor (GCD) being 1. This postcondition
    # states the definition of coprimality: there is no integer d > 1 that
    # divides every number in the list. The search for such a common divisor `d`
    # can be bounded by the minimum element in the list.
    Ensures(Result() == (not any(all(num % d == 0 for num in nums) for d in range(2, min(nums) + 1))))
    return reduce(gcd, nums) == 1