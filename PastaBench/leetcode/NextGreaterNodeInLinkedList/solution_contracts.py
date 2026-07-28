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

class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def nextLargerNodes(head: Optional[ListNode]) -> List[int]:
    nums = []
    while head:
        nums.append(head.val)
        head = head.next
    stk = []
    n = len(nums)
    ans = [0] * n
    for i in range(n - 1, -1, -1):
        Invariant(0 <= i)
        Invariant(i < n)
        Invariant(all(x in nums for x in stk))
        while stk and stk[-1] <= nums[i]:
            stk.pop()
        if stk:
            ans[i] = stk[-1]
        stk.append(nums[i])
    # Every nonzero answer comes from the original list
    Assert(all(a == 0 or a in nums for a in ans))
    return ans