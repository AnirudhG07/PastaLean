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


def rightSideView(root: Optional[TreeNode]) -> List[int]:
    Ensures(root is None or (len(Result()) >= 1 and Result()[0] == root.val))
    ans = []
    if root is None:
        return ans
    Assert(root is not None)
    q = deque([root])
    while q:
        Invariant(len(ans) >= 0)
        # On the first iteration, len(ans) is 0. On all subsequent iterations,
        # ans contains at least root.val from the first iteration.
        Invariant(len(ans) == 0 or (len(ans) > 0 and ans[0] == root.val))
        ans.append(q[0].val)
        for _ in range(len(q)):
            node = q.popleft()
            if node.right:
                q.append(node.right)
            if node.left:
                q.append(node.left)
    # The loop must have run at least once since root is not None, so ans is not empty.
    Assert(len(ans) >= 1 and ans[0] == root.val)
    return ans