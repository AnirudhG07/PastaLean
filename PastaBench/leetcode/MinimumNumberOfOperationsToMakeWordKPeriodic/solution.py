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

def minimumOperationsToMakeKPeriodic(word: str, k: int) -> int:
    n = len(word)
    return n // k - max(Counter((word[i:i + k] for i in range(0, n, k))).values())
