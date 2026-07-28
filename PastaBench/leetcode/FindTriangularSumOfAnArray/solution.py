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

def triangularSum(nums: List[int]) -> int:
    for k in range(len(nums) - 1, 0, -1):
        for i in range(k):
            nums[i] = (nums[i] + nums[i + 1]) % 10
    return nums[0]
