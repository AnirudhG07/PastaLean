from contracts import *
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

def maxChunksToSorted(arr: List[int]) -> int:
    Requires(arr is not None)
    # The number of chunks is between 0 and the length of the array.
    Ensures(0 <= Result() <= len(arr))
    stk: List[int] = []
    for i, v in enumerate(arr):
        # i indexes into arr
        Invariant(0 <= i < len(arr))
        # The stack length never exceeds the number of items processed so far.
        Invariant(0 <= len(stk) <= i + 1)
        # The chunk-maxima stack remains in non-decreasing order.
        Invariant(all(stk[j] <= stk[j+1] for j in range(len(stk)-1)))
        if not stk or v >= stk[-1]:
            stk.append(v)
        else:
            mx = stk.pop()
            while stk and stk[-1] > v:
                stk.pop()
            stk.append(mx)
    # Re-establish the bounds and sortedness before returning
    Assert(0 <= len(stk) <= len(arr))
    Assert(all(stk[j] <= stk[j+1] for j in range(len(stk)-1)))
    return len(stk)