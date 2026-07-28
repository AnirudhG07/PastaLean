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

def hasPathSum(root: Optional[TreeNode], targetSum: int) -> bool:
    def dfs(root, s):
        if root is None:
            return False
        Assert(root is not None)  # now safe to access root.val
        s += root.val
        if root.left is None and root.right is None and (s == targetSum):
            return True
        return dfs(root.left, s) or dfs(root.right, s)
    return dfs(root, 0)