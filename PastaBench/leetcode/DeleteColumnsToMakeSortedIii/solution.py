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

def minDeletionSize(strs: List[str]) -> int:
    n = len(strs[0])
    f = [1] * n
    for i in range(n):
        for j in range(i):
            if all((s[j] <= s[i] for s in strs)):
                f[i] = max(f[i], f[j] + 1)
    return n - max(f)
