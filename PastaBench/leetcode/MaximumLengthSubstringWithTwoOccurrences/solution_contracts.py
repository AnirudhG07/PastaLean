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

def maximumLengthSubstring(s: str) -> int:
    """
    Finds the length of the longest substring of s where each character appears at most twice.
    This is implemented using a sliding window approach.
    """
    Ensures(Result() >= 0)
    Ensures(Result() <= len(s))

    cnt = Counter()
    ans = i = 0
    for j, c in enumerate(s):
        # Loop invariants capture the state at the beginning of each iteration `j`.
        # The variables `i`, `ans`, `cnt` hold their values from the end of iteration `j-1`.

        # 1. Index bounds: `i` is the start of the current valid window `s[i:j]`, and `j` is the
        #    end of the prefix `s[0:j]` being considered.
        Invariant(0 <= j)
        Invariant(j <= len(s))
        Invariant(0 <= i)
        Invariant(i <= j)
        
        # 2. `ans` bound: `ans` is the max length of a valid substring found in the prefix s[0:j].
        Invariant(ans >= 0)
        Invariant(ans <= j)

        # 3. `cnt` properties: `cnt` stores the character counts for the valid window s[i:j].
        # The sum of counts equals the window length.
        Invariant(sum(cnt.values()) == j - i)
        # All counts are non-negative.
        Invariant(all(val >= 0 for val in cnt.values()))
        # The window s[i:j] is "valid": all character counts are at most 2. This is the
        # core property maintained by the sliding window.
        Invariant(all(val <= 2 for val in cnt.values()))

        # Termination measure for the loop.
        Decreases(len(s) - j)
        
        cnt[c] += 1
        while cnt[c] > 2:
            # This loop shrinks the window from the left by advancing `i` until the count of the
            # newest character `c` is no more than 2, restoring the validity of the window.
            cnt[s[i]] -= 1
            i += 1
        
        # After the window is confirmed valid, update the max length found so far.
        ans = max(ans, j - i + 1)
        
    return ans