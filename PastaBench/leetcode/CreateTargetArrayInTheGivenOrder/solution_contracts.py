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

def createTargetArray(nums: List[int], index: List[int]) -> List[int]:
    Requires(len(nums) == len(index))
    Ensures(len(Result()) == len(nums))
    Ensures(sorted(Result()) == sorted(nums))
    target = []
    for x, i in zip(nums, index):
        target.insert(i, x)
    return target