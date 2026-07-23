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

class TreeNode:

    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def averageOfLevels(root: Optional[TreeNode]) -> List[float]:
    Requires(root is not None)
    Ensures(len(Result()) >= 1)       # at least one level for a non-empty tree
    q = deque([root])
    ans = []
    while q:
        s, n = (0, len(q))
        Assert(n > 0)                # non-empty level
        for _ in range(n):
            Invariant(0 <= _)
            Invariant(_ < n)         # ensure safe pops
            root = q.popleft()
            Assert(root is not None)
            s += root.val
            if root.left:
                q.append(root.left)
            if root.right:
                q.append(root.right)
        ans.append(s / n)
    return ans