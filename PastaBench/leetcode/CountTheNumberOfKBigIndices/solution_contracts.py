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
        self.n = n
        self.c = [0] * (n + 1)

    def update(self, x, delta):
        while x <= self.n:
            self.c[x] += delta
            x += x & -x

    def query(self, x):
        s = 0
        while x:
            s += self.c[x]
            x -= x & -x
        return s

def kBigIndices(nums: List[int], k: int) -> int:
    n = len(nums)
    # Caller must supply a valid k and values that fit the tree of size n.
    Requires(k >= 0)
    Requires(all(1 <= v <= n for v in nums))
    # The result counts positions i where at least k prior nums[j]<nums[i]
    # and at least k following nums[j]<nums[i].
    Ensures(
        Result() == sum(
            1
            for i, v in enumerate(nums)
            if sum(1 for j in range(i) if nums[j] < v) >= k
            and sum(1 for j in range(i + 1, n) if nums[j] < v) >= k
        )
    )
    tree1 = BinaryIndexedTree(n)
    tree2 = BinaryIndexedTree(n)
    for v in nums:
        tree2.update(v, 1)
    ans = 0
    for v in nums:
        tree2.update(v, -1)
        ans += (tree1.query(v - 1) >= k and tree2.query(v - 1) >= k)
        tree1.update(v, 1)
    return ans