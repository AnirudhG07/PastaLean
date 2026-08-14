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

def nextGreaterElement(nums1: List[int], nums2: List[int]) -> List[int]:
    Requires(len(set(nums1)) == len(nums1))
    Requires(len(set(nums2)) == len(nums2))
    Requires(set(nums1).issubset(set(nums2)))

    Ensures(len(Result()) == len(nums1))
    # Each result `y` is either -1 (no greater element found) or is an element
    # from nums2 that is strictly greater than its corresponding input `x`.
    Ensures(all((y == -1) or (y > x and y in nums2) for x, y in zip(nums1, Result())))

    stk = []
    d = {}
    for x in nums2[::-1]:
        # The stack always maintains a strictly decreasing sequence of numbers from nums2.
        Invariant(all(stk[i] > stk[i+1] for i in range(len(stk) - 1)))
        Invariant(all(val in nums2 for val in stk))

        # The dictionary `d` stores mappings from an element `k` to its next greater element `v`.
        Invariant(all(k in nums2 and v in nums2 for k, v in d.items()))
        Invariant(all(v > k for k, v in d.items()))

        while stk and stk[-1] < x:
            stk.pop()
        
        if stk:
            # After the inner while loop, stk[-1] must be >= x. Due to the uniqueness of
            # elements in nums2, stk[-1] cannot be equal to x, so it must be strictly greater.
            Assert(stk[-1] > x)
            d[x] = stk[-1]
        
        stk.append(x)
    
    # After the loop, the invariants on `d` hold for the fully computed map.
    Assert(all(v > k for k, v in d.items()))
    Assert(all(k in nums2 and v in nums2 for k, v in d.items()))

    return [d.get(x, -1) for x in nums1]