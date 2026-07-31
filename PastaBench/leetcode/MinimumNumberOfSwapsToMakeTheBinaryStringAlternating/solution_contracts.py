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


def minSwaps(s: str) -> int:
    Requires(s == "" or all(c in ('0', '1') for c in s))
    # The result is -1 if and only if making an alternating string is impossible.
    # This occurs when the counts of '0's and '1's differ by more than 1.
    # Otherwise, the result is non-negative. Note: `2*n0 - len = n0 - n1`.
    Ensures((Result() == -1) == (abs(s.count('0') * 2 - len(s)) > 1))

    def calc(c: int) -> int:
        Requires(c == 0 or c == 1)
        Ensures(Result() >= 0)

        # This expression counts the number of positions where the character in s
        # does not match the target alternating pattern (starting with c).
        mismatches = sum(
            (c ^ (i & 1)) != x for i, x in enumerate(map(int, s))
        )

        # The calling context (abs(n0 - n1) <= 1) guarantees that the number of 0s
        # and 1s in s matches the target pattern. This implies that the number
        # of misplaced 0s (0s in a 1's spot) must equal the number of misplaced
        # 1s (1s in a 0's spot). Therefore, the total number of mismatches is even.
        Assert(mismatches % 2 == 0)

        # Each swap can fix two mismatches (one misplaced 0 and one misplaced 1).
        # So, the minimum number of swaps is half the number of mismatches.
        return mismatches // 2

    n0 = s.count('0')
    n1 = len(s) - n0
    if abs(n0 - n1) > 1:
        return -1
    if n0 == n1:
        # If counts are equal, the length is even. Both "0101..." and "1010..."
        # are valid targets. We need the minimum of the two costs.
        return min(calc(0), calc(1))
    
    # If counts differ by one, the length is odd. Only one target pattern is possible.
    # The pattern must start with the more frequent character.
    return calc(0 if n0 > n1 else 1)