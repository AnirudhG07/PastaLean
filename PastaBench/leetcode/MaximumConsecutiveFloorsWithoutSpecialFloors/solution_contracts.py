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

def maxConsecutive(bottom: int, top: int, special: List[int]) -> int:
    """
    Finds the maximum number of consecutive integers in the range [bottom, top]
    that are not in the `special` list.
    """
    Requires(bottom <= top)
    Requires(len(special) > 0)
    Requires(all(bottom <= s <= top for s in special))

    Ensures(0 <= Result() <= top - bottom)

    special.sort()
    
    # The initial answer is the maximum of the gap at the beginning (from `bottom`
    # to the first special number) and the gap at the end (from the last special
    # number to `top`).
    ans = max(special[0] - bottom, top - special[-1])
    
    # We established that `ans` is non-negative and bounded. This will be the
    # loop invariant.
    Assert(0 <= ans <= top - bottom)

    # Iterate through the gaps between consecutive special numbers.
    for x, y in pairwise(special):
        # Invariant: The running maximum `ans` remains non-negative and bounded
        # by the total range size.
        # This is true because:
        # 1. `ans` starts non-negative.
        # 2. `y - x - 1` can be -1 if duplicates exist (`y==x`), but `max(non_negative, -1)`
        #    is still non-negative.
        # 3. `ans` starts bounded by `top - bottom`.
        # 4. Each new gap `y - x - 1` is also less than `top - bottom` since
        #    `bottom <= x < y <= top`.
        Invariant(0 <= ans <= top - bottom)
        ans = max(ans, y - x - 1)
        
    return ans