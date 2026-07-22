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

def sumOfDigits(nums: List[int]) -> int:
    x = min(nums)
    s = 0
    while x:
        s += x % 10
        x //= 10
    return s & 1 ^ 1
