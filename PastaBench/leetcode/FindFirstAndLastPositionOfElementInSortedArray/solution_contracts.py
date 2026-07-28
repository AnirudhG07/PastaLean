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

def searchRange(nums: List[int], target: int) -> List[int]:
    Requires(all(nums[i] <= nums[i+1] for i in range(len(nums)-1)))
    l = bisect_left(nums, target)
    r = bisect_left(nums, target + 1)
    return [-1, -1] if l == r else [l, r - 1]