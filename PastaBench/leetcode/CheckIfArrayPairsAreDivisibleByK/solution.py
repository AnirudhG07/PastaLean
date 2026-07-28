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

def canArrange(arr: List[int], k: int) -> bool:
    cnt = Counter((x % k for x in arr))
    return cnt[0] % 2 == 0 and all((cnt[i] == cnt[k - i] for i in range(1, k)))
