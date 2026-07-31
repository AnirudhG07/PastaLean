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

def levelOrderBottom(root: Optional[TreeNode]) -> List[List[int]]:
    ans = []
    if root is None:
        return ans
    q = deque([root])
    while q:
        t = []
        for _ in range(len(q)):
            node = q.popleft()
            t.append(node.val)
            if node.left:
                q.append(node.left)
            if node.right:
                q.append(node.right)
        ans.append(t)
    return ans[::-1]
