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

def makeSmallestPalindrome(s: str) -> str:
    Ensures(len(Result()) == len(s))
    Ensures(Result() == Result()[::-1])
    Ensures(Result() <= s)
    cs = list(s)
    i, j = (0, len(s) - 1)
    while i < j:
        Invariant(0 <= i)
        Invariant(j < len(s))
        Invariant(i + j == len(s) - 1)
        # The inner part of cs, from i to j, remains untouched from the original string.
        Invariant(cs[i : j + 1] == list(s)[i : j + 1])
        # The outer parts have been made into a palindrome: for any k < i, cs[k] == cs[len(s)-1-k].
        Invariant(cs[:i] == cs[len(s) - 1 : len(s) - 1 - i : -1])
        Decreases(j - i)

        cs[i] = cs[j] = min(cs[i], cs[j])
        i, j = (i + 1, j - 1)
    return ''.join(cs)