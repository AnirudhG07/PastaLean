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

def minimumSize(nums: List[int], maxOperations: int) -> int:

    def check(mx: int) -> bool:
        return sum(((x - 1) // mx for x in nums)) <= maxOperations
    return bisect_left(range(1, max(nums) + 1), True, key=check) + 1
