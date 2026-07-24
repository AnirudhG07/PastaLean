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

def minOperations(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Requires(all(v >= 0 for v in nums))
    return sum((v.bit_count() for v in nums)) + max(0, max(nums).bit_length() - 1)