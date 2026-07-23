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

def distributeCoins(root: Optional[TreeNode]) -> int:
    Ensures(Result() >= 0)    # The number of moves is non-negative
    def dfs(root):
        if root is None:
            return 0
        left, right = dfs(root.left), dfs(root.right)
        nonlocal ans
        ans += abs(left) + abs(right)
        Assert(ans >= 0)      # Accumulated moves stays non-negative
        return left + right + root.val - 1
    ans = 0
    dfs(root)
    return ans