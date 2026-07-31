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

def findLonely(nums: List[int]) -> List[int]:
    cnt = Counter(nums)
    return [x for x, v in cnt.items() if v == 1 and cnt[x - 1] == 0 and (cnt[x + 1] == 0)]
