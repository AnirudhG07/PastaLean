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

def brokenCalc(startValue: int, target: int) -> int:
    Requires(startValue > 0)
    Requires(target > 0)
    Ensures(Result() >= 0)
    ans = 0
    while startValue < target:
        Invariant(ans >= 0)
        Invariant(target > 0)
        # Termination is guaranteed because `target` is at least halved over any two
        # consecutive iterations, ensuring it eventually falls below `startValue`.
        # However, `target` is not monotonic, so a simple `Decreases` clause is elusive.
        if target & 1:
            target += 1
        else:
            target >>= 1
        ans += 1
    Assert(target <= startValue)
    ans += startValue - target
    return ans