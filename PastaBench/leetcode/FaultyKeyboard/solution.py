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

def finalString(s: str) -> str:
    t = []
    for c in s:
        if c == 'i':
            t = t[::-1]
        else:
            t.append(c)
    return ''.join(t)
