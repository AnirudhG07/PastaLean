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


def timeRequiredToBuy(tickets: List[int], k: int) -> int:
    Requires(0 <= k)
    Requires(k < len(tickets))
    # The total time is the sum, over all people i, of the rounds they take:
    # min(tickets[i], tickets[k]) for i ≤ k, otherwise min(tickets[i], tickets[k] - 1).
    Ensures(
        Result() == sum(
            min(tickets[i], tickets[k] if i <= k else tickets[k] - 1)
            for i in range(len(tickets))
        )
    )
    ans = 0
    for i, x in enumerate(tickets):
        Invariant(0 <= i)
        Invariant(i < len(tickets))
        Invariant(
            ans
            == sum(
                min(tickets[j], tickets[k] if j <= k else tickets[k] - 1)
                for j in range(i)
            )
        )
        Decreases(len(tickets) - i)
        # Bridge the enumerate to indexing
        Assert(x == tickets[i])
        ans += min(x, tickets[k] if i <= k else tickets[k] - 1)
    # Bridge to the postcondition
    Assert(
        ans
        == sum(
            min(tickets[i], tickets[k] if i <= k else tickets[k] - 1)
            for i in range(len(tickets))
        )
    )
    return ans