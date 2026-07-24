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

def minElements(nums: List[int], limit: int, goal: int) -> int:
    Requires(limit > 0)
    Ensures(Result() * limit >= abs(sum(nums) - goal))
    Ensures((Result() - 1) * limit < abs(sum(nums) - goal))
    d = abs(sum(nums) - goal)
    return (d + limit - 1) // limit