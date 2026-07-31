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

def lastSubstring(s: str) -> str:
    i, j, k = (0, 1, 0)
    while j + k < len(s):
        if s[i + k] == s[j + k]:
            k += 1
        elif s[i + k] < s[j + k]:
            i += k + 1
            k = 0
            if i >= j:
                j = i + 1
        else:
            j += k + 1
            k = 0
    return s[i:]
