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

    def dfs(root):
        if root is None:
            return False
        if k - root.val in vis:
            return True
        vis.add(root.val)
        return dfs(root.left) or dfs(root.right)
    vis = set()
    return dfs(root)
