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

def finalPrices(prices: List[int]) -> List[int]:
    stk = []
    for i in reversed(range(len(prices))):
        x = prices[i]
        while stk and x < stk[-1]:
            stk.pop()
        if stk:
            prices[i] -= stk[-1]
        stk.append(x)
    return prices
