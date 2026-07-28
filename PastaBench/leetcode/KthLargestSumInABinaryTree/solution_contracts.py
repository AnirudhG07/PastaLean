from contracts import *
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
    Requires(root is not None)
    Requires(k > 0)
    arr = []
    q = collections.deque([root])
    while q:
        t = 0
        # process one tree level
        n = len(q)
        for _ in range(n):
            node = q.popleft()
            t += node.val
            if node.left:
                q.append(node.left)
            if node.right:
                q.append(node.right)
        arr.append(t)
    # if fewer than k levels, we return -1
    if len(arr) < k:
        Assert(len(arr) < k)
        return -1
    # else there are at least k level sums
    Assert(len(arr) >= k)
    # the k-th largest is the smallest of the top-k values
    topk = heapq.nlargest(k, arr)
    Assert(len(topk) == k)
    return topk[-1]