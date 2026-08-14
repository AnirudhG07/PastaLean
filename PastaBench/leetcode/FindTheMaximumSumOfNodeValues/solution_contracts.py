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
inf = float('inf')

def maximumValueSum(nums: List[int], k: int, edges: List[List[int]]) -> int:
    """
    Calculates the maximum possible sum of node values in a tree after applying an
    operation any number of times. The operation consists of picking an edge and
    XORing the values of its two endpoints with k.
    This is equivalent to choosing an even number of nodes to XOR their values with k.
    The `edges` parameter, while unused in the code, establishes that the graph is a
    tree, which is the justification for this equivalence.
    """
    Requires(len(nums) >= 2)
    Requires(len(edges) == len(nums) - 1)
    Requires(k >= 1)
    Requires(all(x >= 0 for x in nums))
    # THE POINT: The operation can only increase or maintain the total sum.
    # The base case is performing no operations, with a sum of sum(nums).
    Ensures(Result() >= sum(nums))

    # DP state:
    # f0: max sum for the prefix of nums processed so far, with an even number of XOR ops.
    # f1: max sum for the prefix of nums processed so far, with an odd number of XOR ops.
    f0, f1 = (0, -inf)

    for x in nums:
        # f0 is always a sum of non-negative numbers, so it remains non-negative.
        Invariant(f0 >= 0)

        # To have an even number of XORs on the new prefix, we can either:
        # 1. Not XOR x, and have an even number of XORs on the old prefix.
        # 2. XOR x, and have an odd number of XORs on the old prefix.
        f0_next = max(f0 + x, f1 + (x ^ k))

        # To have an odd number of XORs on the new prefix, we can either:
        # 1. Not XOR x, and have an odd number of XORs on the old prefix.
        # 2. XOR x, and have an even number of XORs on the old prefix.
        f1_next = max(f1 + x, f0 + (x ^ k))

        f0, f1 = f0_next, f1_next
    
    # The final answer must come from an even number of XORs in total.
    return f0