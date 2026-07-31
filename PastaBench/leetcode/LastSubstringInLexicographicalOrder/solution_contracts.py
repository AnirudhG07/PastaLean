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

def lastSubstring(s: str) -> str:
    """
    Finds the lexicographically largest substring of a given string s.
    This is equivalent to finding the lexicographically largest suffix of s.
    """
    Ensures(all(Result() >= s[p:] for p in range(len(s))))

    i, j, k = (0, 1, 0)
    while j + k < len(s):
        # --- Loop Invariants ---
        # Bounds for the indices i, j, k. These are crucial for proving memory safety.
        # i is the start of the current best candidate suffix.
        # j is the start of the challenger suffix.
        # k is the length of the common prefix of s[i:] and s[j:].
        Invariant(0 <= i)
        Invariant(i < j)
        Invariant(j <= len(s))
        Invariant(0 <= k)

        # These invariants ensure that array indexing is always safe.
        # The loop condition guarantees j+k is in bounds.
        # Since i < j, i+k is also in bounds.
        Invariant(j + k < len(s))
        Invariant(i + k < len(s))

        # --- Termination Measure ---
        # The quantity (i + j + k) strictly increases in each iteration,
        # and is bounded by 3 * len(s). Thus, the loop must terminate.
        Decreases(3 * len(s) - (i + j + k))
        
        if s[i + k] == s[j + k]:
            # The common prefix is longer.
            k += 1
        elif s[i + k] < s[j + k]:
            # The challenger s[j:] is lexicographically larger than the current best s[i:].
            # The current best candidate s[i:] and all suffixes starting up to i+k are discarded.
            # The new candidate starts at i+k+1.
            i += k + 1
            k = 0
            # Ensure j is always ahead of i.
            if i >= j:
                j = i + 1
        else: # s[i + k] > s[j + k]
            # The current best s[i:] is lexicographically larger than the challenger s[j:].
            # The challenger s[j:] and all suffixes starting up to j+k are discarded.
            # The next challenger starts at j+k+1.
            j += k + 1
            k = 0
    
    # After the loop, i holds the starting index of the lexicographically largest suffix.
    # Assert that i is a valid starting position for a slice.
    Assert(0 <= i <= len(s))
    return s[i:]