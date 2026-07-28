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

def numberOfSteps(num: int) -> int:
    Requires(num >= 0)
    orig = num
    Ensures((orig == 0 and Result() == 0)
            or (orig > 0 and Result() == orig.bit_length() - 1 + orig.bit_count()))
    ans = 0
    while num:
        Invariant(num >= 0)
        Invariant(ans >= 0)
        Decreases(num)
        if num & 1:
            num -= 1
        else:
            num >>= 1
        ans += 1
    return ans