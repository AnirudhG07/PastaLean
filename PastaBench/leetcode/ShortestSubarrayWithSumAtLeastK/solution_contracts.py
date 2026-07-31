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

def shortestSubarray(nums: List[int], k: int) -> int:
    Requires(k > 0)
    Ensures(Result() == -1 or (1 <= Result() <= len(nums)))

    s = list(accumulate(nums, initial=0))
    Assert(len(s) == len(nums) + 1)
    q = deque()
    ans = inf
    # `s` is the prefix sum array where s[i] = sum(nums[0...i-1]).
    # The sum of a subarray nums[j...i-1] is s[i] - s[j].
    # The loop iterates through possible ending positions `i-1` of a subarray.
    # The deque `q` maintains candidate starting positions `j`.
    for i, v in enumerate(s):
        Invariant(0 <= i <= len(s))
        Invariant(ans == inf or (1 <= ans <= len(nums)))
        # At the start of iteration `i`, `q` contains strictly increasing indices
        # from {0, ..., i-1}, which are valid for indexing `s`.
        Invariant(len(q) == 0 or (0 <= q[0] and q[-1] < i))
        Decreases(len(s) - i)

        # If a starting index `q[0]` gives a subarray with sum >= k, record its
        # length. Since `q` is ordered by index, this `q[0]` is the earliest
        # possible start for a valid subarray ending at `i-1`. We can discard it
        # because any later subarray starting at `q[0]` would be longer.
        while q and v - s[q[0]] >= k:
            Assert(len(q) > 0 and 0 <= q[0] < i)
            ans = min(ans, i - q.popleft())

        # To maintain the efficiency of finding the shortest subarray, we keep `q`
        # such that the prefix sums `s[j]` for `j` in `q` are increasing.
        # If `s[q[-1]] >= s[i]`, then `q[-1]` is a worse starting point than `i`
        # for any future subarray, so we discard it.
        while q and s[q[-1]] >= v:
            Assert(len(q) > 0 and 0 <= q[-1] < i)
            q.pop()
            
        q.append(i)
        
    return -1 if ans == inf else int(ans)