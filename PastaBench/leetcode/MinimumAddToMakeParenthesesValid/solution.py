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

def minAddToMakeValid(s: str) -> int:
    stk = []
    for c in s:
        if c == ')' and stk and (stk[-1] == '('):
            stk.pop()
        else:
            stk.append(c)
    return len(stk)
