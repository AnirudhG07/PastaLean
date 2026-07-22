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

def separateDigits(nums: List[int]) -> List[int]:
    ans = []
    for x in nums:
        t = []
        while x:
            t.append(x % 10)
            x //= 10
        ans.extend(t[::-1])
    return ans
