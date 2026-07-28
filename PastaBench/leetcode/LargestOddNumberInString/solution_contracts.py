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

def largestOddNumber(num: str) -> str:
    Requires(all(ch in digits for ch in num))
    Ensures(num.startswith(Result()))
    Ensures((Result() == "") or (Result()[-1] in '13579'))
    Ensures(all(ch not in '13579' for ch in num[len(Result()):]))
    for i in range(len(num) - 1, -1, -1):
        Invariant(0 <= i)
        Invariant(i < len(num))
        Invariant(all(ch not in '13579' for ch in num[i+1:]))
        Decreases(i)
        if int(num[i]) & 1 == 1:
            Assert(num[i] in '13579')
            return num[:i + 1]
    Assert(all(ch not in '13579' for ch in num))
    return ''