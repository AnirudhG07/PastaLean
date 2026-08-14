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

def taskSchedulerII(tasks: List[int], space: int) -> int:
    Requires(space >= 0)
    Ensures(Result() >= len(tasks))

    day = defaultdict(int)
    ans = 0
    for i, task in enumerate(tasks):
        Invariant(0 <= i)
        Invariant(i <= len(tasks))
        Invariant(ans >= i)
        
        ans += 1
        ans = max(ans, day[task])
        day[task] = ans + space + 1
        
    Assert(ans >= len(tasks))
    return ans