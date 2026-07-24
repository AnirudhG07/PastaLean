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

def fourSumCount(nums1: List[int], nums2: List[int], nums3: List[int], nums4: List[int]) -> int:
    cnt = Counter((a + b for a in nums1 for b in nums2))
    return sum((cnt[-(c + d)] for c in nums3 for d in nums4))
