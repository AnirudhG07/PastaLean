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

def minDays(n: int) -> int:

    @cache
    def dfs(n: int) -> int:
        if n < 2:
            return n
        return 1 + min(n % 2 + dfs(n // 2), n % 3 + dfs(n // 3))
    return dfs(n)
