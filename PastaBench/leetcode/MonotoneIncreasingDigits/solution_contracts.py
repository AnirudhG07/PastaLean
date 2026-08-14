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

def monotoneIncreasingDigits(n: int) -> int:
    Requires(n >= 0)
    Ensures(Result() <= n)
    # The primary correctness property: the result's digits are non-decreasing.
    Ensures(all(str(Result())[k] <= str(Result())[k + 1] for k in range(len(str(Result())) - 1)))

    s = list(str(n))
    i = 1
    # Find the first index `i` where the monotone property s[i-1] <= s[i] is violated.
    while i < len(s) and s[i - 1] <= s[i]:
        Invariant(1 <= i <= len(s))
        # The prefix of s up to index i-1 is monotone increasing.
        Invariant(all(s[k] <= s[k + 1] for k in range(i - 1)))
        Decreases(len(s) - i)
        i += 1

    if i < len(s):
        # A violation exists at s[i-1] > s[i].
        Assert(1 <= i < len(s))
        Assert(s[i - 1] > s[i])

        # Backtrack from the violation, decrementing digits to restore the monotone property.
        while i > 0 and s[i - 1] > s[i]:
            Invariant(0 < i)
            Invariant(i < len(s))
            Decreases(i)
            s[i - 1] = str(int(s[i - 1]) - 1)
            i -= 1
        
        # After backtracking, the prefix up to the new `i` is monotonic.
        Assert(i == 0 or s[i - 1] <= s[i])
        
        i += 1
        # `i` now marks the start of the suffix to be filled with '9's.
        # The prefix before this point has been corrected to be monotone.
        Assert(all(s[k] <= s[k + 1] for k in range(i - 1)))

        # Fill the rest of the digits with '9's to get the largest possible number
        # while maintaining the monotone property.
        while i < len(s):
            Invariant(1 <= i <= len(s))
            # The prefix s[0...i-1] is kept monotone.
            Invariant(all(s[k] <= s[k + 1] for k in range(i - 1)))
            Decreases(len(s) - i)
            s[i] = '9'
            i += 1

    # At this point, whether the if-block was taken or not, `s` represents a monotone number.
    Assert(all(s[k] <= s[k + 1] for k in range(len(s) - 1)))
    return int(''.join(s))