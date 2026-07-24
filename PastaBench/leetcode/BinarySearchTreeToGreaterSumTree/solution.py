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

def bstToGst(root: Optional[TreeNode]) -> Optional[TreeNode]:

    def dfs(root: Optional[TreeNode]):
        if root is None:
            return
        dfs(root.right)
        nonlocal s
        s += root.val
        root.val = s
        dfs(root.left)
    s = 0
    dfs(root)
    return root
