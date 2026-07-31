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

def finalString(s: str) -> str:
    Ensures(all(c != 'i' for c in Result()))
    t = []
    for c in s:
        Invariant(all(tc != 'i' for tc in t))
        if c == 'i':
            t = t[::-1]
        else:
            t.append(c)
    Assert(all(tc != 'i' for tc in t))
    return ''.join(t)