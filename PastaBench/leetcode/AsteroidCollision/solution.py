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
    stk = []
    for x in asteroids:
        if x > 0:
            stk.append(x)
        else:
            while stk and stk[-1] > 0 and (stk[-1] < -x):
                stk.pop()
            if stk and stk[-1] == -x:
                stk.pop()
            elif not stk or stk[-1] < 0:
                stk.append(x)
    return stk
