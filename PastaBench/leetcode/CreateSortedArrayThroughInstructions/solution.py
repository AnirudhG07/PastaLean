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

class BinaryIndexedTree:

    def __init__(self, n):
        self.n = n
        self.c = [0] * (n + 1)

    def update(self, x: int, v: int):
        while x <= self.n:
            self.c[x] += v
            x += x & -x

    def query(self, x: int) -> int:
        s = 0
        while x:
            s += self.c[x]
            x -= x & -x
        return s

def createSortedArray(instructions: List[int]) -> int:
    m = max(instructions)
    tree = BinaryIndexedTree(m)
    ans = 0
    mod = 10 ** 9 + 7
    for i, x in enumerate(instructions):
        cost = min(tree.query(x - 1), i - tree.query(x))
        ans += cost
        tree.update(x, 1)
    return ans % mod
