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

def maxProduct(nums: List[int]) -> int:
    # The function computes the maximum product of (n-1)*(m-1) for any two distinct elements
    # n, m in nums. Because `ans` is initialized to 0, the function actually returns
    # max(0, max_product_of_pairs). The contracts capture this behavior.
    Ensures(Result() >= 0)
    Ensures(all(Result() >= (nums[i] - 1) * (nums[j] - 1)
                for i in range(len(nums))
                for j in range(i + 1, len(nums))))

    ans = 0
    for i, a in enumerate(nums):
        Invariant(0 <= i <= len(nums))
        Invariant(ans >= 0)
        # At the start of iteration `i`, `ans` is an upper bound for all products
        # from pairs where the first element's index `k` is less than `i`.
        Invariant(all(ans >= (nums[k] - 1) * (nums[l] - 1)
                      for k in range(i)
                      for l in range(k + 1, len(nums))))

        for b in nums[i + 1:]:
            ans = max(ans, (a - 1) * (b - 1))

    # When the loop terminates, the invariant holds for i = len(nums),
    # which establishes the property over all pairs.
    Assert(all(ans >= (nums[k] - 1) * (nums[l] - 1)
               for k in range(len(nums))
               for l in range(k + 1, len(nums))))
    return ans