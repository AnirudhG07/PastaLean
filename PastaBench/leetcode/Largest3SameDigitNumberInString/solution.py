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

def largestGoodInteger(num: str) -> str:
    for i in range(9, -1, -1):
        if (s := (str(i) * 3)) in num:
            return s
    return ''
