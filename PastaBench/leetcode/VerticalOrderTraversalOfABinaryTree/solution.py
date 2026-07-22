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

def verticalTraversal(root: Optional[TreeNode]) -> List[List[int]]:

    def dfs(root: Optional[TreeNode], i: int, j: int):
        if root is None:
            return
        nodes.append((j, i, root.val))
        dfs(root.left, i + 1, j - 1)
        dfs(root.right, i + 1, j + 1)
    nodes = []
    dfs(root, 0, 0)
    nodes.sort()
    ans = []
    prev = -2000
    for j, _, val in nodes:
        if prev != j:
            ans.append([])
            prev = j
        ans[-1].append(val)
    return ans
