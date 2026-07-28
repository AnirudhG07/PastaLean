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

def printVertically(s: str) -> List[str]:
    words = s.split()
    n = max((len(w) for w in words))
    ans = []
    for j in range(n):
        t = [w[j] if j < len(w) else ' ' for w in words]
        while t[-1] == ' ':
            t.pop()
        ans.append(''.join(t))
    return ans
