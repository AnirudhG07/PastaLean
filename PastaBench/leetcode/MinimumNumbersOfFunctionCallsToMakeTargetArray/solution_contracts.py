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

def minOperations(nums: List[int]) -> int:
    """
    Calculates the minimum number of operations to make an array of zeros
    equal to the target `nums` array.
    The allowed operations are:
    1. Add 1 to any element.
    2. Multiply all elements by 2.
    """
    Requires(len(nums) > 0)
    Requires(all(v >= 0 for v in nums))
    Ensures(Result() >= 0)
    
    # The total number of "add 1" operations is the sum of set bits (1s)
    # for each number. Each '1' bit in the binary representation corresponds
    # to an "add 1" operation at some stage.
    # The number of "multiply by 2" operations is determined by the largest
    # number, as multiplications are applied to the whole array. This is
    # equal to the highest power of 2 needed, which is `max(nums).bit_length() - 1`.
    return sum((v.bit_count() for v in nums)) + max(0, max(nums).bit_length() - 1)