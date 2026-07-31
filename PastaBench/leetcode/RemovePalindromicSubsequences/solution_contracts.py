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

def removePalindromeSub(s: str) -> int:
    """
    Calculates the minimum number of steps to empty a string by removing
    palindromic subsequences. This implementation is correct for non-empty
    strings over an alphabet of at most two characters.
    """
    Requires(len(s) > 0)
    # The logic relies on the alphabet of the string having at most 2 distinct characters.
    # With this constraint, any non-palindrome can be emptied in 2 steps:
    # 1. Remove all instances of the first character (a palindromic subsequence).
    # 2. Remove all instances of the second character (the remainder is a palindrome).
    Requires(len(set(s)) <= 2)

    # The result is 1 if the string is already a palindrome, and 2 otherwise.
    Ensures(0 < Result() <= 2)
    Ensures((s == s[::-1]) == (Result() == 1))

    return 1 if s[::-1] == s else 2