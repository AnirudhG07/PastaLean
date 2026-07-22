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

def maxTotalReward(rewardValues: List[int]) -> int:
    nums = sorted(set(rewardValues))
    f = 1
    for v in nums:
        f |= (f & (1 << v) - 1) << v
    return f.bit_length() - 1
