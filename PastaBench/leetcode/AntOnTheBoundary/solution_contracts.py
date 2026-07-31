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

def returnToBoundaryCount(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(nums))

    count = 0
    current_sum = 0
    for i in range(len(nums)):
        Invariant(0 <= i <= len(nums))
        Invariant(0 <= count)
        Invariant(count <= i)
        
        current_sum += nums[i]
        if current_sum == 0:
            count += 1

    Assert(0 <= count <= len(nums))
    return count