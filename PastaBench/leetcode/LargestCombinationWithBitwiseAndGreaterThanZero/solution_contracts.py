from contracts import *
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

def largestCombination(candidates: List[int]) -> int:
    Requires(len(candidates) > 0)
    Requires(all(c >= 0 for c in candidates))
    Ensures(0 <= Result())
    Ensures(Result() <= len(candidates))

    ans = 0
    limit = max(candidates).bit_length()
    for i in range(limit):
        Invariant(0 <= i <= limit)
        Invariant(0 <= ans)
        Invariant(ans <= len(candidates))
        Decreases(limit - i)

        # The inner expression counts how many numbers in `candidates`
        # have the i-th bit set. This count must be between 0 and len(candidates).
        # `ans` is the running maximum of these counts.
        ans = max(ans, sum((x >> i & 1 for x in candidates)))
    
    Assert(0 <= ans <= len(candidates))
    return ans