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

def pathInZigZagTree(label: int) -> List[int]:
    Requires(label >= 1)
    Ensures(len(Result()) > 0)
    Ensures(Result()[0] == 1)

    x = i = 1
    # This loop finds the depth `i` of the node `label`.
    # `x` tracks the first label `2**(i-1)` of level `i` in a standard tree.
    # The loop terminates when `2**(i-1) <= label < 2**i`.
    while x << 1 <= label:
        Invariant(i >= 1)
        Invariant(x == 1 << (i - 1))
        # The loop guard `2*x <= label` with `x > 0` implies `x < label`.
        # Since `x` doubles each time, `label - x` strictly decreases and remains positive.
        Decreases(label - x)

        x <<= 1
        i += 1
    
    # After the loop, `i` is the depth of `label`, and `2**(i-1) <= label < 2**i`.
    Assert(i >= 1)
    Assert((1 << (i - 1)) <= label and label < (1 << i))

    ans = [0] * i
    # This loop works backwards from the node at `label` up to the root, filling `ans`.
    while i: # This is equivalent to `while i > 0`
        # Loop Invariant: `i` is the current depth, and `label` is a valid node at this depth.
        Invariant(1 <= i and i <= len(ans))
        Invariant((1 << (i - 1)) <= label and label < (1 << i))
        Decreases(i)

        ans[i - 1] = label
        # Calculate the parent's label for the next level up.
        label = (1 << i - 1) + (1 << i) - 1 - label >> 1
        i -= 1

    # The last iteration of the loop was for `i=1`.
    # The invariant `1 <= label < 2` forced `label` to be 1.
    # This value was stored in `ans[0]`.
    Assert(ans[0] == 1)
    return ans