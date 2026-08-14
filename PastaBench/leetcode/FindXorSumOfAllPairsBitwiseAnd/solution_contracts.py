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

def getXORSum(arr1: List[int], arr2: List[int]) -> int:
    Requires(len(arr1) > 0)
    Requires(len(arr2) > 0)
    # The point of this function is its equivalence to the XOR sum of the bitwise AND of
    # all pairs of elements from the two arrays, based on the distributive property of
    # bitwise AND over bitwise XOR.
    # (XOR a_i) & (XOR b_j) == XOR_{i,j} (a_i & b_j)
    Ensures(Result() == reduce(xor, [a & b for a in arr1 for b in arr2]))
    a = reduce(xor, arr1)
    b = reduce(xor, arr2)
    return a & b