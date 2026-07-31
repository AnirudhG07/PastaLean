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

def sortVowels(s: str) -> str:
    vs = [c for c in s if c.lower() in 'aeiou']
    vs.sort()
    cs = list(s)
    j = 0
    for i, c in enumerate(cs):
        if c.lower() in 'aeiou':
            cs[i] = vs[j]
            j += 1
    return ''.join(cs)
