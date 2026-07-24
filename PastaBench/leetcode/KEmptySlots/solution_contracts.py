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

class BinaryIndexedTree:

    def __init__(self, n):
        Requires(n >= 0)
        self.n = n
        self.c = [0] * (n + 1)

    def update(self, x, delta):
        Requires(1 <= x <= self.n)
        # ensure we never go out of bounds on c
        Invariant(1 <= x)
        Invariant(x <= self.n)
        Decreases(self.n + 1 - x)
        while x <= self.n:
            self.c[x] += delta
            x += x & -x

    def query(self, x):
        Requires(0 <= x <= self.n)
        s = 0
        Invariant(0 <= x)
        Invariant(x <= self.n)
        Decreases(x)
        while x:
            s += self.c[x]
            x -= x & -x
        return s

def kEmptySlots(bulbs: List[int], k: int) -> int:
    Requires(len(bulbs) > 0)
    Requires(len(set(bulbs)) == len(bulbs))
    Requires(k >= 0)
    # result is either -1 or a valid day index in [1..len(bulbs)]
    Ensures(-1 <= Result() <= len(bulbs))

    n = len(bulbs)
    tree = BinaryIndexedTree(n)
    vis = [False] * (n + 1)
    for i, x in enumerate(bulbs, 1):
        # Bounds for x and i
        Assert(1 <= x <= n)
        Assert(1 <= i <= n)
        tree.update(x, 1)
        vis[x] = True

        # check left neighbor
        y = x - k - 1
        if y > 0 and vis[y] and (tree.query(x - 1) - tree.query(y) == 0):
            return i
        # check right neighbor
        y = x + k + 1
        if y <= n and vis[y] and (tree.query(y - 1) - tree.query(x) == 0):
            return i

    return -1