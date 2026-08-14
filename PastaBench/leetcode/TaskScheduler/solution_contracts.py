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

def leastInterval(tasks: List[str], n: int) -> int:
    Requires(len(tasks) > 0)
    Requires(n >= 0)

    # The result must be at least the total number of tasks, which is a fundamental lower bound.
    Ensures(Result() >= len(tasks))
    # Since len(tasks) > 0, the result is positive.
    Ensures(Result() > 0)

    cnt = Counter(tasks)
    x = max(cnt.values())
    # Since tasks is non-empty, the frequency of the most common task is at least 1.
    Assert(x >= 1)

    s = sum((v == x for v in cnt.values()))
    # There must be at least one task with the maximum frequency.
    Assert(s >= 1)
    # The number of tasks with maximum frequency cannot exceed the number of unique tasks.
    Assert(s <= len(cnt))

    return max(len(tasks), (x - 1) * (n + 1) + s)