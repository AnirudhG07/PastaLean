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

def goodNodes(root: TreeNode) -> int:

    def dfs(root: TreeNode, mx: int):
        if root is None:
            return
        nonlocal ans
        if mx <= root.val:
            ans += 1
            mx = root.val
        dfs(root.left, mx)
        dfs(root.right, mx)
    ans = 0
    dfs(root, -1000000)
    return ans
