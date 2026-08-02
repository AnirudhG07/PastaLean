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

def canArrange(arr: List[int], k: int) -> bool:
    # This function intends to check if `arr` can be partitioned into pairs (a,b)
    # such that `(a+b) % k == 0`. The implementation has a subtle bug for even `k`.
    # The postcondition describes the *correct* logic, which will expose the bug
    # during verification, as the implementation fails to establish it.
    Requires(k > 0)
    Ensures(
        Result() == (lambda counts:
            counts[0] % 2 == 0 and
            all(counts[i] == counts[k - i] for i in range(1, (k + 1) // 2)) and
            (k % 2 != 0 or counts[k // 2] % 2 == 0)
        )(Counter(x % k for x in arr))
    )
    cnt = Counter((x % k for x in arr))
    return cnt[0] % 2 == 0 and all((cnt[i] == cnt[k - i] for i in range(1, k)))