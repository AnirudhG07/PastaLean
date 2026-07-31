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

def addToArrayForm(num: List[int], k: int) -> List[int]:
    Requires(len(num) >= 1)
    Requires(all(0 <= d <= 9 for d in num))
    # No leading zeros, except for the number 0 itself.
    Requires(len(num) == 1 or num[0] != 0)
    Requires(k >= 0)

    # All elements of the result are single digits.
    Ensures(all(0 <= d <= 9 for d in Result()))
    # The result has no leading zeros, unless the number is 0 itself.
    Ensures(len(Result()) == 1 or Result()[0] != 0)

    ans = []
    i = len(num) - 1
    while i >= 0 or k:
        # Index `i` remains in a range that is valid for the initial `num`.
        Invariant(i < len(num))
        # The carry `k` is always non-negative.
        Invariant(k >= 0)
        # All digits accumulated so far are valid.
        Invariant(all(0 <= d <= 9 for d in ans))

        k += 0 if i < 0 else num[i]
        k, x = divmod(k, 10)
        ans.append(x)
        i -= 1

    # The loop terminates only when the carry is fully processed.
    Assert(k == 0)
    return ans[::-1]