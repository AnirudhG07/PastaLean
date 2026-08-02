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

def findMaximumLength(nums: List[int]) -> int:
    # This algorithm finds the maximum length of a partition of `nums` into subarrays
    # with non-decreasing sums. It requires positive numbers to ensure the prefix sums
    # array `s` is strictly increasing, which is necessary for `bisect_left`.
    Requires(All(x >= 1 for x in nums))
    Ensures(0 <= Result() <= len(nums))

    n = len(nums)
    s = list(accumulate(nums, initial=0))
    Assert(len(s) == n + 1)
    Assert(s[0] == 0)
    # Strict monotonicity of `s` is guaranteed by the precondition.
    Assert(All(s[k] < s[k+1] for k in range(n)))

    f = [0] * (n + 1)
    pre = [0] * (n + 2)
    Assert(len(f) == n + 1 and f[0] == 0)
    Assert(len(pre) == n + 2)

    for i in range(1, n + 1):
        Invariant(1 <= i <= n + 1)
        # `f[k]` stores the max partition length for `nums[:k]`, so `f[k] <= k`.
        Invariant(All(0 <= f[k] <= k for k in range(i)))
        # `pre[k]` is the start index of the last segment for `nums[:k]`, so `pre[k] < k`.
        Invariant(All(0 <= pre[k] < k for k in range(1, i)))
        # `pre` is maintained to be non-decreasing up to the current point.
        Invariant(All(pre[k] <= pre[k+1] for k in range(i - 1)))
        Decreases(n + 1 - i)

        pre[i] = max(pre[i], pre[i - 1])
        # After this update, `pre[i]` is a valid index into prefixes of `f` and `s`.
        Assert(0 <= pre[i] < i)

        f[i] = f[pre[i]] + 1
        Assert(1 <= f[i] <= i)

        target = s[i] * 2 - s[pre[i]]
        j = bisect_left(s, target)

        # `s` is strictly increasing, so `s[i] * 2 - s[pre[i]] > s[i]`.
        # This guarantees `bisect_left` finds an index `j > i`.
        # The largest possible `j` is `len(s) = n + 1`.
        Assert(i < j <= n + 1)
        # The update to `pre[j]` is safe as `len(pre) == n + 2`.
        Assert(j < len(pre))
        pre[j] = i

    # The loop computes f[n], which is the final result.
    # The invariant for i = n + 1 implies this property.
    Assert(0 <= f[n] <= n)
    return f[n]