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

def minMoves(nums: List[int]) -> int:
    Requires(len(nums) > 0)
    Ensures(Result() == sum(nums) - min(nums) * len(nums))
    return sum(nums) - min(nums) * len(nums)