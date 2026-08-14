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

def longestDecomposition(text: str) -> int:
    ans = 0
    i, j = (0, len(text) - 1)
    while i <= j:
        k = 1
        ok = False
        while i + k - 1 < j - k + 1:
            if text[i:i + k] == text[j - k + 1:j + 1]:
                ans += 2
                i += k
                j -= k
                ok = True
                break
            k += 1
        if not ok:
            ans += 1
            break
    return ans
