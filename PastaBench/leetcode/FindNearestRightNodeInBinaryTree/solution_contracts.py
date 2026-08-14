import heapq
import itertools
from sortedcontainers import SortedList
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
from contracts import *

class TreeNode:

    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right

def findNearestRightNode(root: TreeNode, u: TreeNode) -> Optional[TreeNode]:
    Requires(root is not None)
    Requires(u is not None)
    Ensures(Result() is not u)
    q = deque([root])
    while q:
        for i in range(len(q) - 1, -1, -1):
            Invariant(i >= 0)
            # The queue contains at least `i` elements from the current level.
            # This is sufficient to prove memory safety of the `q[0]` access below.
            Invariant(len(q) >= i)
            root = q.popleft()
            if root == u:
                if i:
                    Assert(i > 0)
                    Assert(len(q) > 0)
                    return q[0]
                else:
                    return None
            if root.left:
                q.append(root.left)
            if root.right:
                q.append(root.right)