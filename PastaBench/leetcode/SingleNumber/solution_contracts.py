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

def singleNumber(nums: List[int]) -> int:
    """
    Given a non-empty array of integers nums, every element appears twice except for one. Find that single one.
    This implementation uses the property that A xor A = 0.
    """
    Requires(len(nums) > 0)
    # The result is the number that, when XORed with the XOR sum of the original list, yields 0.
    # This is equivalent to saying that if we append the result to the list, the XOR sum of the new
    # list is 0, which implies every element in the new list appears an even number of times.
    Ensures(reduce(xor, nums + [Result()]) == 0)
    return reduce(xor, nums)