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

def closestKValues(root: TreeNode, target: float, k: int) -> List[int]:

    def dfs(root):
        if root is None:
            return
        dfs(root.left)
        if len(q) < k:
            q.append(root.val)
        else:
            if abs(root.val - target) >= abs(q[0] - target):
                return
            q.popleft()
            q.append(root.val)
        dfs(root.right)
    q = deque()
    dfs(root)
    return list(q)
