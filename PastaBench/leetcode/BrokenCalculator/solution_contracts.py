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

def brokenCalc(startValue: int, target: int) -> int:
    Requires(startValue > 0)
    Requires(target > 0)
    ans = 0
    while startValue < target:
        if target & 1:
            target += 1
        else:
            target >>= 1
        ans += 1
    ans += startValue - target
    return ans