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

def oddEvenList(head: Optional[ListNode]) -> Optional[ListNode]:
    if head is None:
        return None
    a = head
    b = c = head.next
    while b and b.next:
        a.next = b.next
        a = a.next
        b.next = a.next
        b = b.next
    a.next = c
    return head
