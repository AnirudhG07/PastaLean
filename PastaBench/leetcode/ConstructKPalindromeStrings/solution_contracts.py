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

def canConstruct(s: str, k: int) -> bool:
    Requires(k >= 0)
    if len(s) < k:
        return False
    cnt = Counter(s)
    odd = sum(v & 1 for v in cnt.values())
    return odd <= k