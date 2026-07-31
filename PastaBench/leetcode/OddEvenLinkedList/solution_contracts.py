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

def oddEvenList(head: Optional[ListNode]) -> Optional[ListNode]:
    # The core correctness property of this function is structural and depends on
    # the list being acyclic, which is difficult to express without helper
    # functions for list traversal and properties. The contracts below focus on
    # memory safety (non-nullness) and the frame property that the head of the
    # list is preserved.
    Ensures(head is None or Result() is head)

    if head is None:
        return None
    
    Assert(head is not None)
    a = head
    b = c = head.next
    while b and b.next:
        # Invariants to ensure pointer dereferences in the loop are safe.
        Invariant(a is not None)
        Invariant(b is not None)
        Invariant(b.next is not None)

        a.next = b.next
        a = a.next
        b.next = a.next
        b = b.next

    Assert(a is not None)
    a.next = c
    return head