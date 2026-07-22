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

def pairSum(head: Optional[ListNode]) -> int:
    s = []
    while head:
        s.append(head.val)
        head = head.next
    n = len(s)
    return max((s[i] + s[-(i + 1)] for i in range(n >> 1)))
