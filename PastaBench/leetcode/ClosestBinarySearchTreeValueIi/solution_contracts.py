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

def closestKValues(root: TreeNode, target: float, k: int) -> List[int]:
    # This function is correct only for a non-empty tree if k > 0.
    # It will raise an IndexError for k=0 on a non-empty tree.
    Requires(k >= 0 and (root is None or k > 0))

    # The function is intended to be called on a Binary Search Tree.
    # A key property of the in-order traversal used is that it visits nodes
    # in sorted order. This implies the final list of values will be sorted.
    Ensures(all(Result()[i] <= Result()[i + 1] for i in range(len(Result()) - 1)))
    # The number of values returned is at most k.
    Ensures(len(Result()) <= k)

    def dfs(root):
        if root is None:
            return
        dfs(root.left)
        if len(q) < k:
            q.append(root.val)
        else:
            # This comparison prunes the search space. It relies on the
            # in-order traversal visiting nodes with increasing values.
            if abs(root.val - target) >= abs(q[0] - target):
                return
            q.popleft()
            q.append(root.val)
        dfs(root.right)
    q = deque()
    dfs(root)
    # Asserting the invariants on the state of `q` just before returning
    # helps bridge the gap for the postcondition proofs.
    Assert(len(q) <= k)
    Assert(all(list(q)[i] <= list(q)[i + 1] for i in range(len(q) - 1)))
    return list(q)