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

def findNumbers(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(nums))
    return sum((len(str(x)) % 2 == 0 for x in nums))