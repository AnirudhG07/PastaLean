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


def countExcellentPairs(nums: List[int], k: int) -> int:
    Requires(all(x >= 0 for x in nums))
    Requires(k >= 0)
    Ensures(Result() == sum(1 for v1 in set(nums) for v2 in set(nums) if v1.bit_count() + v2.bit_count() >= k))

    s = set(nums)
    ans = 0
    cnt = Counter()

    for v in s:
        cnt[v.bit_count()] += 1

    # Assert that 'cnt' correctly represents the histogram of bit counts over the unique numbers.
    # This property is essential for the correctness of the second loop.
    Assert(set(cnt.keys()) == {v.bit_count() for v in s})
    Assert(all(cnt[bc] == sum(1 for v in s if v.bit_count() == bc) for bc in cnt.keys()))

    for v in s:
        t = v.bit_count()
        for i, x in cnt.items():
            if t + i >= k:
                ans += x

    # Assert that the final accumulated value of 'ans' is the total count of excellent pairs,
    # which directly leads to the postcondition.
    Assert(ans == sum(1 for v1 in s for v2 in s if v1.bit_count() + v2.bit_count() >= k))
    return ans