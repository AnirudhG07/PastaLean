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

def buildArray(target: List[int], n: int) -> List[str]:
    ans = []
    cur = 1
    for x in target:
        while cur < x:
            ans.extend(['Push', 'Pop'])
            cur += 1
        ans.append('Push')
        cur += 1
    return ans
