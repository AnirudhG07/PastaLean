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

def rangeSumBST(root: Optional[TreeNode], low: int, high: int) -> int:

    def dfs(root: Optional[TreeNode]) -> int:
        if root is None:
            return 0
        x = root.val
        ans = x if low <= x <= high else 0
        if x > low:
            ans += dfs(root.left)
        if x < high:
            ans += dfs(root.right)
        return ans
    return dfs(root)
