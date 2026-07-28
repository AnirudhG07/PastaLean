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

def validateStackSequences(pushed: List[int], popped: List[int]) -> bool:
    stk = []
    i = 0
    for x in pushed:
        stk.append(x)
        while stk and stk[-1] == popped[i]:
            stk.pop()
            i += 1
    return i == len(popped)
