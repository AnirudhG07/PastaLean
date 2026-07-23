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

def _vals(root: Optional[TreeNode]) -> list[int]:
    """Helper: in-order flattening of the tree's values."""
    if root is None:
        return []
    return _vals(root.left) + [root.val] + _vals(root.right)

def rangeSumBST(root: Optional[TreeNode], low: int, high: int) -> int:
    """Return the sum of all node values v in the BST with low <= v <= high."""
    # No structural preconditions beyond a well-formed tree.
    Ensures(Result() == sum(v for v in _vals(root) if low <= v <= high))

    def dfs(node: Optional[TreeNode]) -> int:
        # Point: dfs(node) = sum of filtered _vals(node).
        Ensures(Result() == sum(v for v in _vals(node) if low <= v <= high))
        if node is None:
            return 0
        x = node.val
        ans = x if low <= x <= high else 0
        if x > low:
            ans += dfs(node.left)
        if x < high:
            ans += dfs(node.right)
        return ans

    return dfs(root)