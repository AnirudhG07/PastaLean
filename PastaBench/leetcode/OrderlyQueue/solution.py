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

def orderlyQueue(s: str, k: int) -> str:
    if k == 1:
        ans = s
        for _ in range(len(s) - 1):
            s = s[1:] + s[0]
            ans = min(ans, s)
        return ans
    return ''.join(sorted(s))
