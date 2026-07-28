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

def sumOfNumberAndReverse(num: int) -> bool:
    Requires(num >= 0)
    Ensures(Result() == any(k + int(str(k)[::-1]) == num for k in range(num + 1)))
    return any((k + int(str(k)[::-1]) == num for k in range(num + 1)))