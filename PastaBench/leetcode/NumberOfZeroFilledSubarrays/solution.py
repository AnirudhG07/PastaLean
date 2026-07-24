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

def zeroFilledSubarray(nums: List[int]) -> int:
    ans = cnt = 0
    for v in nums:
        cnt = 0 if v else cnt + 1
        ans += cnt
    return ans
