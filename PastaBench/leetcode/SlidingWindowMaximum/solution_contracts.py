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

def maxSlidingWindow(nums: List[int], k: int) -> List[int]:
    Requires(k > 0)
    Ensures(len(Result()) == max(0, len(nums) - k + 1))

    # We use a min-heap to find the max by storing negated values.
    # The heap stores pairs of (-value, index).
    q = [(-v, i) for i, v in enumerate(nums[:k - 1])]
    heapify(q)
    ans = []

    # `i` is the index of the right edge of the sliding window.
    for i in range(k - 1, len(nums)):
        Invariant(k - 1 <= i < len(nums))
        # The length of `ans` tracks the number of windows processed.
        Invariant(len(ans) == i - (k - 1))
        # Elements in the heap are from indices processed so far.
        Invariant(all(0 <= t[1] < i for t in q))
        # Heap values correspond to the original `nums` values.
        Invariant(all(-t[0] == nums[t[1]] for t in q))

        heappush(q, (-nums[i], i))
        Assert(len(q) > 0)

        # Remove elements from the heap's top if they are outside the current window.
        # The window is `nums[i-k+1 ... i]`, so indices `<= i-k` are stale.
        while q[0][1] <= i - k:
            Invariant(len(q) > 0)
            Decreases(len(q))
            heappop(q)

        # After cleaning, the max element (top of heap) is guaranteed to be in the current window.
        Assert(len(q) > 0)
        Assert(i - k < q[0][1] <= i)

        ans.append(-q[0][0])
    
    Assert(len(ans) == max(0, len(nums) - k + 1))
    return ans