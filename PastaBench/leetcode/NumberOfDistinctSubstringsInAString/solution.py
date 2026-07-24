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

def countDistinct(s: str) -> int:
    n = len(s)
    return len({s[i:j] for i in range(n) for j in range(i + 1, n + 1)})
