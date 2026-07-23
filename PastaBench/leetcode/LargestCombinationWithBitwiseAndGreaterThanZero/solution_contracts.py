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

def largestCombination(candidates: List[int]) -> int:
    Requires(len(candidates) > 0)
    ans = 0
    for i in range(max(candidates).bit_length()):
        ans = max(ans, sum((x >> i & 1 for x in candidates)))
    return ans