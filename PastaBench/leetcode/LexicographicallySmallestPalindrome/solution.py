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

def makeSmallestPalindrome(s: str) -> str:
    cs = list(s)
    i, j = (0, len(s) - 1)
    while i < j:
        cs[i] = cs[j] = min(cs[i], cs[j])
        i, j = (i + 1, j - 1)
    return ''.join(cs)
