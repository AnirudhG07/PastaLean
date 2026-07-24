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

def canDivideIntoSubsequences(nums: List[int], k: int) -> bool:
    Requires(len(nums) > 0)
    # The function returns True exactly when the longest run of equal elements,
    # multiplied by k, does not exceed the total list length.
    return max((len(list(x)) for _, x in groupby(nums))) * k <= len(nums)