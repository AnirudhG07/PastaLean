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

def numRabbits(answers: List[int]) -> int:
    cnt = Counter(answers)
    ans = 0
    for x, v in cnt.items():
        group = x + 1
        ans += (v + group - 1) // group * group
    return ans
