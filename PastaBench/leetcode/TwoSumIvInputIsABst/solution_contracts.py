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

def findTarget(root: Optional[TreeNode], k: int) -> bool:
    # No precondition on root (it may be None) and k can be any int.
    def dfs(node: Optional[TreeNode]) -> bool:
        if node is None:
            return False
        # If we've seen a value that pairs with node.val to sum to k, we succeed.
        if k - node.val in vis:
            Assert(k - node.val in vis)   # USEFUL: bridge the guard so the proof knows this fact
            return True
        vis.add(node.val)
        # Recurse left or right looking for a match
        return dfs(node.left) or dfs(node.right)

    vis: set[int] = set()
    return dfs(root)