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
class ListNode:

    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

def swapNodes(head: Optional[ListNode], k: int) -> Optional[ListNode]:
    Requires(k >= 1)
    Requires(head is not None)
    Ensures(Result() == head)
    fast = slow = head
    for _ in range(k - 1):
        Invariant(fast is not None)
        fast = fast.next
    Assert(fast is not None)
    p = fast
    while fast.next:
        Invariant(fast is not None)
        Invariant(slow is not None)
        fast, slow = (fast.next, slow.next)
    Assert(slow is not None)
    q = slow
    p.val, q.val = (q.val, p.val)
    return head