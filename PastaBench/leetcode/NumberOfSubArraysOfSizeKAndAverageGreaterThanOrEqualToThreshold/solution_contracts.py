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

def numOfSubarrays(arr: List[int], k: int, threshold: int) -> int:
    Requires(k > 0)
    Requires(len(arr) >= k)
    Ensures(0 <= Result())
    Ensures(Result() <= len(arr) - k + 1)

    threshold *= k
    s = sum(arr[:k])
    ans = int(s >= threshold)
    Assert(s == sum(arr[0:k]))
    Assert(0 <= ans <= 1)

    for i in range(k, len(arr)):
        Invariant(k <= i <= len(arr))
        Invariant(s == sum(arr[i - k : i]))
        Invariant(0 <= ans <= i - k + 1)
        Decreases(len(arr) - i)

        s += arr[i] - arr[i - k]
        Assert(s == sum(arr[i - k + 1 : i + 1]))
        ans += int(s >= threshold)

    Assert(0 <= ans <= len(arr) - k + 1)
    return ans