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

def minFlips(target: str) -> int:
    ans = 0
    for v in target:
        if ans & 1 ^ int(v):
            ans += 1
    return ans
