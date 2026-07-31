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

def minImpossibleOR(nums: List[int]) -> int:
    s = set(nums)
    return next((1 << i for i in range(32) if 1 << i not in s))
