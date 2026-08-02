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

def countDistinctStrings(s: str, k: int) -> int:
    # This formula likely arises from a combinatorial problem on a binary string of length n=len(s),
    # where an operation is to flip a substring of length k. There are n-k+1 such substrings,
    # and if the operations are independent, there are 2^(n-k+1) possible outcomes.
    # For this to be well-defined:
    # 1. The number of operations must be non-negative: len(s) - k + 1 >= 0, so k <= len(s) + 1.
    #    This ensures the exponent to pow() is non-negative, yielding an integer result.
    # 2. The length k is typically positive in such problems, so k >= 1.
    Requires(k >= 1 and k <= len(s) + 1)
    Ensures(Result() == pow(2, len(s) - k + 1) % (10 ** 9 + 7))
    return pow(2, len(s) - k + 1) % (10 ** 9 + 7)