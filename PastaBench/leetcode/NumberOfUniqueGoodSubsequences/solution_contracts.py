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

def numberOfUniqueGoodSubsequences(binary: str) -> int:
    Requires(all(c in '01' for c in binary))
    Ensures(0 <= Result() < 1000000007)

    f = g = 0
    ans = 0
    mod = 10 ** 9 + 7
    for c in binary:
        Invariant(mod == 10 ** 9 + 7)
        # Invariants about the DP state variables:
        # f: count of good subsequences ending in '1'
        # g: count of good subsequences ending in '0' (excluding "0" itself)
        # ans: flag indicating if "0" has been seen, for the special case
        Invariant(0 <= f < mod)
        Invariant(0 <= g < mod)
        Invariant(ans == 0 or ans == 1)

        if c == '0':
            g = (g + f) % mod
            ans = 1
        else:
            f = (f + g + 1) % mod

    # After the loop, `ans` correctly records if a '0' was ever seen.
    Assert(ans == (1 if '0' in binary else 0))
    ans = (ans + f + g) % mod
    return ans