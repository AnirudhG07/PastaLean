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

def minimumMoves(s: str) -> int:
    ans = i = 0
    while i < len(s):
        if s[i] == 'X':
            ans += 1
            i += 3
        else:
            i += 1
    return ans
