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

def commonChars(words: List[str]) -> List[str]:
    Requires(len(words) > 0)
    # The result characters must be a subset of the characters in the first word.
    Ensures(set(Result()).issubset(set(words[0])))
    # The total number of characters in the result is bounded by the length of the first word.
    Ensures(len(Result()) <= len(words[0]))

    cnt = Counter(words[0])
    for w in words:
        # Invariant: The set of characters being tracked is a subset of the initial set from words[0],
        # as new characters are never added.
        Invariant(set(cnt.keys()).issubset(set(words[0])))
        # Invariant: The total count of characters is non-increasing. Since it starts at len(words[0]),
        # it remains bounded by it.
        Invariant(sum(cnt.values()) <= len(words[0]))

        t = Counter(w)
        for c in cnt:
            cnt[c] = min(cnt[c], t[c])
    
    # The Ensures clauses follow directly from the state of `cnt` at loop exit,
    # as established by the invariants.
    # `len(list(cnt.elements()))` is `sum(cnt.values())`.
    # `set(list(cnt.elements()))` is a subset of `set(cnt.keys())`.
    return list(cnt.elements())