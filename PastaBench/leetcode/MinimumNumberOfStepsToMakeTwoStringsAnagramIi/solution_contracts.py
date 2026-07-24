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

def minSteps(s: str, t: str) -> int:
    Ensures(Result() == sum(abs(Counter(s)[c] - Counter(t)[c]) for c in set(s) | set(t)))
    cnt = Counter(s)
    for c in t:
        cnt[c] -= 1
    return sum(abs(v) for v in cnt.values())