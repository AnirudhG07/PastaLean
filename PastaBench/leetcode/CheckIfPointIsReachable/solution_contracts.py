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

from contracts import *

def isReachable(targetX: int, targetY: int) -> bool:
    Requires(targetX >= 0 and targetY >= 0)
    Ensures(Result() == ((gcd(targetX, targetY) & (gcd(targetX, targetY) - 1)) == 0))
    x = gcd(targetX, targetY)
    return x & (x - 1) == 0