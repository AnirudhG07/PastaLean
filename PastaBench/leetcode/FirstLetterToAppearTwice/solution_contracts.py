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


def repeatedCharacter(s: str) -> str:
    Requires(len(set(s)) < len(s))
    Ensures(s.count(Result()) >= 2)
    cnt = Counter()
    for c in s:
        # Invariant: until we return, no character has yet been seen more than once.
        Invariant(all(v == 1 for v in cnt.values()))
        cnt[c] += 1
        if cnt[c] == 2:
            return c