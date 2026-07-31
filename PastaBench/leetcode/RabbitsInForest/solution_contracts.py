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

def numRabbits(answers: List[int]) -> int:
    Requires(all(a >= 0 for a in answers))
    Ensures(Result() >= 0)
    Ensures(Result() >= len(answers))

    cnt = Counter(answers)
    ans = 0
    for x, v in cnt.items():
        Invariant(x >= 0)
        Invariant(v > 0)
        Invariant(ans >= 0)

        group = x + 1
        # The number of rabbits for a color group must be a multiple of the group size,
        # and must be large enough to account for the `v` rabbits who gave this answer.
        # This is equivalent to `ceil(v/group) * group`.
        Assert((v + group - 1) // group * group >= v)

        ans += (v + group - 1) // group * group

    Assert(ans >= len(answers))
    return ans