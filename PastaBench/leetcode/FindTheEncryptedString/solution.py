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

def getEncryptedString(s: str, k: int) -> str:
    cs = list(s)
    n = len(s)
    for i in range(n):
        cs[i] = s[(i + k) % n]
    return ''.join(cs)
