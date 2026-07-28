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

def closestNodes(root: Optional[TreeNode], queries: List[int]) -> List[List[int]]:

    def dfs(root: Optional[TreeNode]):
        if root is None:
            return
        dfs(root.left)
        nums.append(root.val)
        dfs(root.right)
    nums = []
    dfs(root)
    ans = []
    for x in queries:
        i = bisect_left(nums, x + 1) - 1
        j = bisect_left(nums, x)
        mi = nums[i] if 0 <= i < len(nums) else -1
        mx = nums[j] if 0 <= j < len(nums) else -1
        ans.append([mi, mx])
    return ans
