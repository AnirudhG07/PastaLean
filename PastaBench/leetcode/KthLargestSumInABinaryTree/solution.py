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

def kthLargestLevelSum(root: Optional[TreeNode], k: int) -> int:
    arr = []
    q = deque([root])
    while q:
        t = 0
        for _ in range(len(q)):
            root = q.popleft()
            t += root.val
            if root.left:
                q.append(root.left)
            if root.right:
                q.append(root.right)
        arr.append(t)
    return -1 if len(arr) < k else nlargest(k, arr)[-1]
