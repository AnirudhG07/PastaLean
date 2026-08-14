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

def findDuplicate(nums: List[int]) -> int:

    def f(x: int) -> bool:
        return sum((v <= x for v in nums)) > x
    return bisect_left(range(len(nums)), True, key=f)
