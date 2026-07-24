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

def maxConsecutive(bottom: int, top: int, special: List[int]) -> int:
    special.sort()
    ans = max(special[0] - bottom, top - special[-1])
    for x, y in pairwise(special):
        ans = max(ans, y - x - 1)
    return ans
