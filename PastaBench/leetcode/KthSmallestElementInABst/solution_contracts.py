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

def kthSmallest(root: Optional[TreeNode], k: int) -> int:
    Requires(root is not None)
    Requires(k >= 1)
    stk = []
    while root or stk:
        if root:
            stk.append(root)
            root = root.left
        else:
            root = stk.pop()
            k -= 1
            if k == 0:
                return root.val
            root = root.right