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

def customSortString(order: str, s: str) -> str:
    d = {c: i for i, c in enumerate(order)}
    return ''.join(sorted(s, key=lambda x: d.get(x, 0)))
