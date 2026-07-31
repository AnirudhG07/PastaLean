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

def countDistinctIntegers(nums: List[int]) -> int:
    s = set(nums)
    for x in nums:
        y = int(str(x)[::-1])
        s.add(y)
    return len(s)
