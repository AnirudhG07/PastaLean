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

def reverseList(head: ListNode) -> ListNode:
    dummy = ListNode()
    curr = head
    while curr:
        next = curr.next
        curr.next = dummy.next
        dummy.next = curr
        curr = next
    return dummy.next
