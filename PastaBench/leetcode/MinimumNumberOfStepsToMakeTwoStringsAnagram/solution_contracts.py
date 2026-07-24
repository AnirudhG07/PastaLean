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

def minSteps(s: str, t: str) -> int:
    Ensures(Result() >= 0)
    cnt = Counter(s)
    ans = 0
    for c in t:
        Invariant(ans >= 0)
        cnt[c] -= 1
        ans += cnt[c] < 0
    return ans