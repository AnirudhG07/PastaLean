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

def frequenciesOfElements(head: Optional[ListNode]) -> Optional[ListNode]:
    cnt = Counter()
    while head:
        cnt[head.val] += 1
        head = head.next
    dummy = ListNode()
    for val in cnt.values():
        # Each frequency is positive
        Assert(val > 0)
        dummy.next = ListNode(val, dummy.next)
    # The result list contains only positive integers
    node = dummy.next
    while node:
        Assert(node.val > 0)
        node = node.next
    return dummy.next