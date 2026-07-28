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

def buildArray(nums: List[int]) -> List[int]:
    Requires(all(0 <= x < len(nums) for x in nums))
    Ensures(len(Result()) == len(nums))
    Ensures(all(Result()[i] == nums[nums[i]] for i in range(len(nums))))
    return [nums[num] for num in nums]