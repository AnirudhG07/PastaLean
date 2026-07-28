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


def fillCups(amount: List[int]) -> int:
    Requires(len(amount) == 3)
    Requires(amount[0] >= 0)
    Requires(amount[1] >= 0)
    Requires(amount[2] >= 0)
    Ensures(sum(amount) == 0)
    ans = 0
    while sum(amount):
        Invariant(ans >= 0)
        Invariant(sum(amount) >= 0)
        Decreases(sum(amount))
        amount.sort()
        ans += 1
        amount[2] -= 1
        amount[1] = max(0, amount[1] - 1)
    Assert(sum(amount) == 0)
    return ans