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

def getMaximumConsecutive(coins: List[int]) -> int:
    Requires(all(v > 0 for v in coins))
    ans = 1
    for v in sorted(coins):
        Invariant(ans > 0)
        Invariant(ans <= 1 + sum(coins))
        if v > ans:
            break
        ans += v
    return ans