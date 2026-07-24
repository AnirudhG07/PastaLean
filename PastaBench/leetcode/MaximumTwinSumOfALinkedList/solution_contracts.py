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

def pairSum(head: Optional[ListNode]) -> int:
    Requires(head is not None)
    Requires(head.next is not None)
    s = []
    while head:
        s.append(head.val)
        head = head.next
    # Compute all twin sums of the list
    pairs = [s[i] + s[-(i + 1)] for i in range(len(s) >> 1)]
    # The result is one of these computed pair sums
    res = max(pairs)
    Assert(res in pairs)
    return res