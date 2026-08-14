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

def maximizeGreatness(nums: List[int]) -> int:
    Ensures(0 <= Result() <= len(nums))
    nums.sort()
    i = 0
    # In a `for-each` loop, the verifier introduces an implicit loop counter,
    # conventionally named `__loop_iter_0`.
    for x in nums:
        Invariant(0 <= i)
        # The number of successful pairings `i` cannot exceed the number of elements
        # (`__loop_iter_0`) examined so far. This is the core invariant that
        # also guarantees the memory safety of the access `nums[i]`, since it implies
        # `i <= __loop_iter_0 < len(nums)`.
        Invariant(i <= __loop_iter_0)
        Invariant(i <= len(nums))
        i += x > nums[i]
    return i