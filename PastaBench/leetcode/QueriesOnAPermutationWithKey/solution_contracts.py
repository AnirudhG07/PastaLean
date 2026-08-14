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

def processQueries(queries: List[int], m: int) -> List[int]:
    Requires(m >= 1)
    Requires(all(1 <= v <= m for v in queries))

    Ensures(len(Result()) == len(queries))
    Ensures(all(0 <= j < m for j in Result()))

    p = list(range(1, m + 1))
    ans = []
    for v in queries:
        # INVARIANT: p always contains a permutation of the numbers from 1 to m.
        # This is the core semantic property of the state `p`.
        Invariant(len(p) == m)
        Invariant(all(1 <= x <= m for x in p))
        Invariant(len(set(p)) == len(p))  # This establishes uniqueness of elements

        # INVARIANT: The accumulated results `ans` are all valid indices into a list of size m.
        Invariant(all(0 <= j < m for j in ans))

        # The invariants above and the precondition on `queries` are sufficient to
        # prove that `v` is in `p`, so `p.index(v)` will not raise an exception.
        j = p.index(v)
        ans.append(j)
        p.pop(j)
        p.insert(0, v)
    return ans