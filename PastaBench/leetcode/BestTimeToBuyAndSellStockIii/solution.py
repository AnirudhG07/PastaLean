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

def maxProfit(prices: List[int]) -> int:
    f1, f2, f3, f4 = (-prices[0], 0, -prices[0], 0)
    for price in prices[1:]:
        f1 = max(f1, -price)
        f2 = max(f2, f1 + price)
        f3 = max(f3, f2 - price)
        f4 = max(f4, f3 + price)
    return f4
