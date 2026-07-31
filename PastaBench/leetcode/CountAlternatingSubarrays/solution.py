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

def countAlternatingSubarrays(nums: List[int]) -> int:
    ans = s = 1
    for a, b in pairwise(nums):
        s = s + 1 if a != b else 1
        ans += s
    return ans
