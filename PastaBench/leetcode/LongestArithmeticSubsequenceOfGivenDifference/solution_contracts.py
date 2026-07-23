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

def longestSubsequence(arr: List[int], difference: int) -> int:
    Requires(len(arr) > 0)
    f = defaultdict(int)
    for x in arr:
        f[x] = f[x - difference] + 1
    return max(f.values())