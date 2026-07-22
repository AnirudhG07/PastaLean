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

def numComponents(head: Optional[ListNode], nums: List[int]) -> int:
    ans = 0
    s = set(nums)
    while head:
        while head and head.val not in s:
            head = head.next
        ans += head is not None
        while head and head.val in s:
            head = head.next
    return ans
