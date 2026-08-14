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

class BinaryIndexedTree:

    def __init__(self, n):
        Requires(n >= 0)
        self.n = n
        self.c = [0] * (n + 1)

    def update(self, x, v):
        Requires(1 <= x <= self.n)
        while x <= self.n:
            Invariant(1 <= x)
            Decreases(self.n - x)
            self.c[x] += v
            x += x & -x

    def query(self, x):
        Requires(0 <= x <= self.n)
        s = 0
        while x > 0:
            Invariant(0 <= x <= self.n)
            Decreases(x)
            s += self.c[x]
            x -= x & -x
        return s

def countRangeSum(nums: List[int], lower: int, upper: int) -> int:
    Requires(lower <= upper)
    Ensures(Result() >= 0)
    Ensures(Result() * 2 <= len(nums) * (len(nums) + 1))
    
    s = list(accumulate(nums, initial=0))
    Assert(len(s) == len(nums) + 1)

    arr = sorted(set((v for x in s for v in (x, x - lower, x - upper))))
    tree = BinaryIndexedTree(len(arr))
    ans = 0
    for x in s:
        Invariant(ans >= 0)

        # The values `x-upper` and `x-lower` are present in `arr` by construction.
        # `bisect_left` on a value present in the list returns an index in `[0, len(arr)-1]`.
        # The BIT's indices are 1-based, hence the `+ 1`.
        l = bisect_left(arr, x - upper) + 1
        r = bisect_left(arr, x - lower) + 1
        
        Assert(1 <= l <= len(arr))
        Assert(1 <= r <= len(arr))
        Assert(l <= r)  # Follows from Requires(lower <= upper)

        # These assertions establish the preconditions for the tree methods.
        Assert(0 <= r <= tree.n)
        Assert(0 <= l - 1 <= tree.n)
        ans += tree.query(r) - tree.query(l - 1)
        
        update_idx = bisect_left(arr, x) + 1
        Assert(1 <= update_idx <= tree.n)
        tree.update(update_idx, 1)
    return ans