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

def predictPartyVictory(senate: str) -> str:
    Requires(len(senate) > 0)
    Requires(all(c in ('R', 'D') for c in senate))
    Ensures(Result() == 'Radiant' or Result() == 'Dire')

    qr = deque()
    qd = deque()
    for i, c in enumerate(senate):
        if c == 'R':
            qr.append(i)
        else:
            qd.append(i)
    n = len(senate)
    while qr and qd:
        # INVARIANT: The indices representing senator priorities are always non-negative.
        Invariant(all(v >= 0 for v in qr))
        Invariant(all(v >= 0 for v in qd))
        # INVARIANT: The total number of senators must be at least 1. This is true
        # initially (n > 0), and preserved since the loop requires at least two
        # senators to run and the count only decreases by one. This guarantees
        # that at loop exit, at least one party remains.
        Invariant(len(qr) + len(qd) >= 1)
        # DECREASES: The total number of active senators across both parties decreases
        # by exactly one in each round of voting (two are removed, one is
        # re-added), ensuring the process terminates.
        Decreases(len(qr) + len(qd))
        
        if qr[0] < qd[0]:
            qr.append(qr[0] + n)
        else:
            qd.append(qd[0] + n)
        qr.popleft()
        qd.popleft()
    return 'Radiant' if qr else 'Dire'