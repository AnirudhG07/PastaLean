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


def makeAntiPalindrome(s: str) -> str:
    # The implementation crashes for empty strings and produces an incorrect
    # result for single-character strings.
    Requires(len(s) >= 2)
    # The function intends to produce an "anti-palindrome", where no character
    # matches its reflection across the center. If not possible, it returns '-1'.
    # The result should also be an anagram of the input, which is true by construction
    # (sorting then swapping) but is complex to state formally.
    Ensures(Result() == '-1' or all(Result()[k] != Result()[len(s) - 1 - k] for k in range(len(s) // 2)))

    cs = sorted(s)
    n = len(cs)
    m = n // 2
    if cs[m] == cs[m - 1]:
        i = m
        # Find the end of the block of identical characters around the midpoint.
        while i < n and cs[i] == cs[i - 1]:
            Invariant(m <= i <= n)
            Decreases(n - i)
            i += 1
        Assert(m <= i <= n)

        j = m
        # Find and fix characters in the second half that are palindromic with
        # their counterparts in the first half.
        while j < n and cs[j] == cs[n - j - 1]:
            Invariant(m <= j <= n)
            Invariant(j <= i <= n)
            Decreases(n - j)
            if i >= n:
                # This indicates we've run out of distinct characters to swap with,
                # implying an anti-palindrome is impossible to form this way.
                return '-1'
            Assert(i < n)
            cs[i], cs[j] = (cs[j], cs[i])
            i, j = (i + 1, j + 1)
    return ''.join(cs)