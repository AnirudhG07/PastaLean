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
    q = deque([root])
    ans = []
    while q:
        s, n = (0, len(q))
        for _ in range(n):
            root = q.popleft()
            s += root.val
            if root.left:
                q.append(root.left)
            if root.right:
                q.append(root.right)
        ans.append(s / n)
    return ans
