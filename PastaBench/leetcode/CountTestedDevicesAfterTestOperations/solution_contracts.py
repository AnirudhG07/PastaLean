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

def countTestedDevices(batteryPercentages: List[int]) -> int:
    # The result is the H-index: the largest k such that at least k entries are ≥ k.
    Ensures(sum(1 for x in batteryPercentages if x >= Result()) >= Result())
    Ensures(all(sum(1 for x in batteryPercentages if x >= k) < k
                for k in range(Result() + 1, len(batteryPercentages) + 1)))
    ans = 0
    for x in batteryPercentages:
        ans += x > ans
    return ans