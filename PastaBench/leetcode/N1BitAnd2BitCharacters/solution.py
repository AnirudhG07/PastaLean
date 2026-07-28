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

def isOneBitCharacter(bits: List[int]) -> bool:
    i, n = (0, len(bits))
    while i < n - 1:
        i += bits[i] + 1
    return i == n - 1
