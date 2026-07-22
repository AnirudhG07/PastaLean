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

def kthSmallest(mat: List[List[int]], k: int) -> int:
    pre = [0]
    for cur in mat:
        pre = sorted((a + b for a in pre for b in cur[:k]))[:k]
    return pre[-1]
