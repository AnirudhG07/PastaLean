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

def reverseList(head: ListNode) -> ListNode:
    # A key property is that reversing an empty list yields an empty list,
    # and reversing a non-empty list yields a non-empty list.
    Ensures((head is None) == (Result() is None))
    dummy = ListNode()
    curr = head
    while curr:
        # Invariant: The `dummy.next` pointer, which tracks the head of the reversed portion,
        # is non-None after the first node has been processed. `curr is head` is a proxy
        # for "the first node has not yet been processed". Once `curr` advances,
        # `dummy.next` will be non-None and will remain so.
        Invariant(curr is head or dummy.next is not None)
        next = curr.next
        curr.next = dummy.next
        dummy.next = curr
        curr = next
    return dummy.next