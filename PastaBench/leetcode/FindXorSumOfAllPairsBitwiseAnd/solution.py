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

def getXORSum(arr1: List[int], arr2: List[int]) -> int:
    a = reduce(xor, arr1)
    b = reduce(xor, arr2)
    return a & b
