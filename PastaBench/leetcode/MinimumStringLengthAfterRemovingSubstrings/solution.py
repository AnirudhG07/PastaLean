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

def minLength(s: str) -> int:
    stk = ['']
    for c in s:
        if c == 'B' and stk[-1] == 'A' or (c == 'D' and stk[-1] == 'C'):
            stk.pop()
        else:
            stk.append(c)
    return len(stk) - 1
