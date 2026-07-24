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

def isIdealPermutation(nums: List[int]) -> bool:
    mx = 0
    for i in range(2, len(nums)):
        if (mx := max(mx, nums[i - 2])) > nums[i]:
            return False
    return True
