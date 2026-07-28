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
    return sum((max(0, b - a) for a, b in pairwise(prices)))
