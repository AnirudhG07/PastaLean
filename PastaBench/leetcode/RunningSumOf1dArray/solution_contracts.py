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

def runningSum(nums: List[int]) -> List[int]:
    Ensures(len(Result()) == len(nums))
    Ensures(all(Result()[i] == sum(nums[:i+1]) for i in range(len(nums))))
    return list(accumulate(nums))