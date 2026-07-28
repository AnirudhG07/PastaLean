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
        dummy.next = ListNode(val, dummy.next)
    return dummy.next
