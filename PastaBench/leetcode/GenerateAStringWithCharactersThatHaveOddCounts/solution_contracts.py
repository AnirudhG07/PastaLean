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

def generateTheString(n: int) -> str:
    Requires(n >= 1)
    Ensures(len(Result()) == n)
    # The returned string has every character an odd number of times.
    Ensures(all(Result().count(c) % 2 == 1 for c in set(Result())))
    if n & 1:
        return 'a' * n
    else:
        return 'a' * (n - 1) + 'b'