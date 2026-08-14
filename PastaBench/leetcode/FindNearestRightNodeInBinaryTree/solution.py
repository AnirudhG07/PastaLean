import heapq
import itertools
from sortedcontainers import SortedList
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

def findNearestRightNode(root: TreeNode, u: TreeNode) -> Optional[TreeNode]:
    q = deque([root])
    while q:
        for i in range(len(q) - 1, -1, -1):
            root = q.popleft()
            if root == u:
                return q[0] if i else None
            if root.left:
                q.append(root.left)
            if root.right:
                q.append(root.right)
