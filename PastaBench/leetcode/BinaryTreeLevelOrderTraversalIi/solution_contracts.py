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

def levelOrderBottom(root: Optional[TreeNode]) -> List[List[int]]:
    Ensures((root is None) == (len(Result()) == 0))
    Ensures(root is None or Result()[-1] == [root.val])

    ans = []
    if root is None:
        return ans
        
    Assert(root is not None)
    
    q = deque([root])
    while q:
        Invariant(len(ans) == 0 or ans[0] == [root.val])
        
        t = []
        for _ in range(len(q)):
            node = q.popleft()
            Assert(node is not None)
            
            t.append(node.val)
            if node.left:
                q.append(node.left)
            if node.right:
                q.append(node.right)
        ans.append(t)

    Assert(len(ans) > 0)
    Assert(ans[0] == [root.val])
    
    return ans[::-1]