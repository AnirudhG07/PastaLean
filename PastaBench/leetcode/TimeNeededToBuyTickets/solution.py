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

def timeRequiredToBuy(tickets: List[int], k: int) -> int:
    ans = 0
    for i, x in enumerate(tickets):
        ans += min(x, tickets[k] if i <= k else tickets[k] - 1)
    return ans
