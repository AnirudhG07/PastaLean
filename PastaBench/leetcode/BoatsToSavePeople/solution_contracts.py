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

def numRescueBoats(people: List[int], limit: int) -> int:
    Requires(limit > 0)
    Requires(all(0 < p <= limit for p in people))
    Ensures(2 * Result() >= len(people))
    Ensures(Result() <= len(people))

    people.sort()
    ans = 0
    i, j = (0, len(people) - 1)
    
    while i <= j:
        # INVARIANTS
        # The pointers `i` and `j` must remain within the bounds of the list.
        Invariant(0 <= i)
        Invariant(j < len(people))
        # The pointers `i` and `j` define a shrinking window of people to be saved.
        # They can meet or cross by at most one position.
        Invariant(i <= j + 1)
        # The number of light people paired up (`i`) cannot exceed the number of boats used (`ans`).
        Invariant(i <= ans)
        # `ans` boats have been used, and each boat corresponds to one person from the heavy end
        # being seated. `j` points to the heaviest person not yet on a boat.
        Invariant(ans + j == len(people) - 1)
        # The distance between pointers `j` and `i` strictly decreases, ensuring termination.
        Decreases(j - i)

        if people[i] + people[j] <= limit:
            i += 1
        j -= 1
        ans += 1
    return ans