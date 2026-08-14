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

def findTheDifference(s: str, t: str) -> str:
    # The function's purpose is to find the single character that was added to a string `s`
    # to create the string `t`. This implies that `t` is a permutation of `s` plus one character.
    Requires(len(t) == len(s) + 1)

    # The relationship between `s`, `t`, and the result can be expressed as a conservation law
    # on the sum of character ordinal values. The total "ordinal mass" of `t` must equal that
    # of `s` plus the mass of the single returned character. This postcondition captures the
    # full functional intent and is only provable if the implicit multiset relationship holds.
    Ensures(sum(ord(c) for c in t) == sum(ord(c) for c in s) + ord(Result()))

    cnt = Counter(s)
    for c in t:
        cnt[c] -= 1
        if cnt[c] < 0:
            return c
    # This path is unreachable under the assumption that `t` is a superset of `s`
    # with one extra character, as the loop is guaranteed to find that character.