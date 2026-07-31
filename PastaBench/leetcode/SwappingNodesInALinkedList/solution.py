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

def swapNodes(head: Optional[ListNode], k: int) -> Optional[ListNode]:
    fast = slow = head
    for _ in range(k - 1):
        fast = fast.next
    p = fast
    while fast.next:
        fast, slow = (fast.next, slow.next)
    q = slow
    p.val, q.val = (q.val, p.val)
    return head
