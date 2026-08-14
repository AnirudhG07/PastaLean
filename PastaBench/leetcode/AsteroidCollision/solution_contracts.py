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

def asteroidCollision(asteroids: List[int]) -> List[int]:
    Requires(all(a != 0 for a in asteroids))
    Ensures(all(not (Result()[i] > 0 and Result()[i+1] < 0) for i in range(len(Result()) - 1)))
    Ensures(all(a != 0 for a in Result()))
    stk = []
    for x in asteroids:
        Invariant(all(not (stk[i] > 0 and stk[i+1] < 0) for i in range(len(stk) - 1)))
        Invariant(all(s != 0 for s in stk))
        if x > 0:
            stk.append(x)
        else:
            while stk and stk[-1] > 0 and (stk[-1] < -x):
                Invariant(all(not (stk[i] > 0 and stk[i+1] < 0) for i in range(len(stk) - 1)))
                Invariant(len(stk) > 0)
                Invariant(stk[-1] > 0)
                Invariant(x < 0)
                Decreases(len(stk))
                stk.pop()
            if stk and stk[-1] > 0 and stk[-1] == -x:
                stk.pop()
            elif not stk or stk[-1] < 0:
                stk.append(x)
    Assert(all(not (stk[i] > 0 and stk[i+1] < 0) for i in range(len(stk) - 1)))
    return stk