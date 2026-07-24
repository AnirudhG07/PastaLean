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

def divisibilityArray(word: str, m: int) -> List[int]:
    ans = []
    x = 0
    for c in word:
        x = (x * 10 + int(c)) % m
        ans.append(1 if x == 0 else 0)
    return ans
