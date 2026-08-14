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

def maxHeight(cuboids: List[List[int]]) -> int:
    Requires(len(cuboids) > 0)
    Requires(all(len(c) == 3 for c in cuboids))
    Requires(all(all(d >= 0 for d in c) for c in cuboids))
    # The result is at least the height of any single cuboid.
    # Note: `cuboids` is modified in-place, this postcondition refers
    # to the state of `cuboids` at the end of the function.
    Ensures(all(Result() >= c[2] for c in cuboids))
    Ensures(Result() >= 0)

    # This first loop standardizes cuboids by sorting their dimensions.
    # The height of a cuboid is its largest dimension.
    for c in cuboids:
        c.sort()
    # After this, for any cuboid c, c[2] is its height.
    Assert(all(c[0] <= c[1] and c[1] <= c[2] for c in cuboids))

    # This sort is key to the DP approach. It orders cuboids to
    # ensure that any potential base for a cuboid `i` is found at an index `j < i`.
    cuboids.sort()

    n = len(cuboids)
    # f[i] will store the maximum height of a stack ending with cuboid `i`.
    f = [0] * n
    Assert(len(f) == n)

    for i in range(n):
        # --- Outer loop invariants ---
        # Loop counter bounds.
        Invariant(0 <= i <= n)
        # Array length invariants for proving memory safety.
        Invariant(len(f) == n)
        Invariant(len(cuboids) == n)
        # Key DP property: for all fully processed cuboids `k < i`, f[k] is at least
        # the height of the cuboid itself, as a single-cuboid stack is always possible.
        Invariant(all(f[k] >= cuboids[k][2] for k in range(i)))
        # All computed heights in `f` must be non-negative.
        Invariant(all(x >= 0 for x in f))

        # Find the max height of a valid stack that can be placed under cuboid `i`.
        for j in range(i):
            # --- Inner loop invariants ---
            # Loop counter bounds.
            Invariant(0 <= j <= i)
            # `i` is fixed from the outer loop, and is in a valid range.
            Invariant(0 <= i < n)
            # Array length invariants.
            Invariant(len(f) == n)
            Invariant(len(cuboids) == n)
            # `f[i]` accumulates the max height of a supporting stack; it starts at 0
            # and only increases or stays the same, so it remains non-negative.
            Invariant(f[i] >= 0)
            
            # The check for a valid stack: cuboid `j` can be placed under `i`.
            # We already know cuboids[j][0] <= cuboids[i][0] because of the
            # top-level sort on the `cuboids` list.
            if cuboids[j][1] <= cuboids[i][1] and cuboids[j][2] <= cuboids[i][2]:
                f[i] = max(f[i], f[j])
        
        # After the inner loop, `f[i]` holds the max height of a stack *under* cuboid `i`.
        # Now add the height of cuboid `i` itself.
        f[i] += cuboids[i][2]
        # This establishes the main invariant for `f[i]`.
        Assert(f[i] >= cuboids[i][2])

    # After the loop, the key invariant holds for the entire array `f`.
    Assert(all(f[k] >= cuboids[k][2] for k in range(n)))
    
    # The final result is the maximum height found over all possible stacks.
    return max(f)