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

def numWaterBottles(numBottles: int, numExchange: int) -> int:
    ans = numBottles
    while numBottles >= numExchange:
        numBottles -= numExchange - 1
        ans += 1
    return ans
