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
from contracts import *

def waysToBuyPensPencils(total: int, cost1: int, cost2: int) -> int:
    Requires(cost1 > 0 and cost2 > 0)
    Ensures(Result() == sum((total - x * cost1) // cost2 + 1 for x in range(total // cost1 + 1)))
    ans = 0
    for x in range(total // cost1 + 1):
        Invariant(0 <= x)
        Invariant(x <= total // cost1 + 1)
        Invariant(ans == sum((total - i * cost1) // cost2 + 1 for i in range(x)))
        Decreases(total // cost1 + 1 - x)
        y = (total - x * cost1) // cost2 + 1
        ans += y
    # Bridge: at exit, ans equals the full sum specified in the postcondition
    Assert(ans == sum((total - x * cost1) // cost2 + 1 for x in range(total // cost1 + 1)))
    return ans