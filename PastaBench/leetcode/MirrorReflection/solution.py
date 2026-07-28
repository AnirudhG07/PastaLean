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

def mirrorReflection(p: int, q: int) -> int:
    g = gcd(p, q)
    p = p // g % 2
    q = q // g % 2
    if p == 1 and q == 1:
        return 1
    return 0 if p == 1 else 2
