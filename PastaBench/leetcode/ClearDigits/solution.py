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

def clearDigits(s: str) -> str:
    stk = []
    for c in s:
        if c.isdigit():
            stk.pop()
        else:
            stk.append(c)
    return ''.join(stk)
