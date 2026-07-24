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

def equalToDescendants(root: Optional[TreeNode]) -> int:

    def dfs(root):
        if root is None:
            return 0
        l, r = (dfs(root.left), dfs(root.right))
        if l + r == root.val:
            nonlocal ans
            ans += 1
        return root.val + l + r
    ans = 0
    dfs(root)
    return ans
