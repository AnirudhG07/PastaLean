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

def zeroFilledSubarray(nums: List[int]) -> int:
    Ensures(Result() >= 0)
    ans = cnt = 0
    for v in nums:
        Invariant(cnt >= 0)
        Invariant(ans >= 0)
        cnt = 0 if v else cnt + 1
        ans += cnt
    return ans