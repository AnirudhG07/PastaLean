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

def numOfSubarrays(arr: List[int], k: int, threshold: int) -> int:
    threshold *= k
    s = sum(arr[:k])
    ans = int(s >= threshold)
    for i in range(k, len(arr)):
        s += arr[i] - arr[i - k]
        ans += int(s >= threshold)
    return ans
