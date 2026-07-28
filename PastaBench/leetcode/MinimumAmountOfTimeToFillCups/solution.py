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

def fillCups(amount: List[int]) -> int:
    ans = 0
    while sum(amount):
        amount.sort()
        ans += 1
        amount[2] -= 1
        amount[1] = max(0, amount[1] - 1)
    return ans
