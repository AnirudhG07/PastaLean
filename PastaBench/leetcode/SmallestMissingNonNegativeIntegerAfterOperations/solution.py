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

def findSmallestInteger(nums: List[int], value: int) -> int:
    cnt = Counter((x % value for x in nums))
    for i in range(len(nums) + 1):
        if cnt[i % value] == 0:
            return i
        cnt[i % value] -= 1
