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

def findFinalValue(nums: List[int], original: int) -> int:
    Ensures(Result() not in set(nums))
    while original in set(nums):
        original <<= 1
    Assert(original not in set(nums))
    return original