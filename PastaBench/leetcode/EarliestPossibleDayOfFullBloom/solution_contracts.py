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

def earliestFullBloom(plantTime: List[int], growTime: List[int]) -> int:
    Requires(len(plantTime) == len(growTime))
    Requires(all(t >= 0 for t in plantTime))
    Requires(all(t >= 0 for t in growTime))

    Ensures(Result() >= 0)
    Ensures(Result() >= sum(plantTime))

    ans = 0
    t = 0
    for pt, gt in sorted(zip(plantTime, growTime), key=lambda x: -x[1]):
        Invariant(t >= 0)
        Invariant(ans >= 0)
        Invariant(ans >= t)

        t += pt
        ans = max(ans, t + gt)

    Assert(t == sum(plantTime))
    Assert(ans >= t)
    return ans