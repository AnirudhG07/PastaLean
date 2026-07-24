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


def kthSmallest(mat: List[List[int]], k: int) -> int:
    Requires(k >= 1)
    Requires(len(mat) >= 1)
    Requires(all(len(row) >= 1 for row in mat))
    pre = [0]
    for cur in mat:
        Invariant(len(pre) >= 1)
        Invariant(len(pre) <= k)
        pre = sorted((a + b for a in pre for b in cur[:k]))[:k]
    Assert(len(pre) >= 1)
    return pre[-1]