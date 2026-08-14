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

def repeatedSubstringPattern(s: str) -> bool:
    """
    Checks if a non-empty string can be constructed by taking a proper substring of it
    and appending multiple copies of the substring together.
    """
    Requires(len(s) > 0)
    Ensures(Result() == any(
        len(s) % k == 0 and s == s[0:k] * (len(s) // k)
        for k in range(1, len(s))
    ))
    return (s + s).index(s, 1) < len(s)