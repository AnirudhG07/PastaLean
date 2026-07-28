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

def minimumArrayLength(nums: List[int]) -> int:
    mi = min(nums)
    if any((x % mi for x in nums)):
        return 1
    return (nums.count(mi) + 1) // 2
