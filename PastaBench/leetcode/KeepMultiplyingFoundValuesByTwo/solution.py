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
    s = set(nums)
    while original in s:
        original <<= 1
    return original
