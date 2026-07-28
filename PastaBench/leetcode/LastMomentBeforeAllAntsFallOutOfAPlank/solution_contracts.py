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

def getLastMoment(n: int, left: List[int], right: List[int]) -> int:
    Requires(n >= 0)
    # The result is the maximum of left distances and right distances to the ends.
    Ensures(Result() == max(left + [0] + [n - x for x in right]))
    ans = 0
    for x in left:
        ans = max(ans, x)
    # After processing left, ans == max(left ∪ {0})
    Assert(ans == max(left + [0]))
    for x in right:
        ans = max(ans, n - x)
    # After processing right, ans == max(left ∪ {0} ∪ {n - x | x ∈ right})
    Assert(ans == max(left + [0] + [n - x for x in right]))
    return ans