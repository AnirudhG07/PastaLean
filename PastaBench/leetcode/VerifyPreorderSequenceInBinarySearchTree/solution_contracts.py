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
inf = float('inf')

def verifyPreorder(preorder: List[int]) -> bool:
    stk = []
    last = -inf
    for x in preorder:
        if x < last:
            return False
        Assert(x >= last)                      # USEFUL: bridges the guard, so we know x ≥ last for the logic below
        while stk and stk[-1] < x:
            last = stk.pop()
        stk.append(x)
    return True