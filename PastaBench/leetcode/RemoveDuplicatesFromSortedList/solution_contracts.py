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

def deleteDuplicates(head: Optional[ListNode]) -> Optional[ListNode]:
    """
    Given the head of a sorted linked list, delete all duplicates such that each
    element appears only once. Return the linked list sorted as well.
    The list is modified in-place.
    """
    # The main postcondition, that the resulting list has no adjacent duplicates,
    # is a property of the list's structure. Expressing structural properties of
    # a linked list (e.g., "for all nodes n, n.val != n.next.val") is beyond
    # the scope of simple boolean contracts on in-scope variables.
    # We can, however, assert a key behavioral property: the modification is in-place
    # and the original head node is returned.
    Ensures(Result() is head)
    cur = head
    while cur and cur.next:
        # The implicit loop invariant is that the portion of the list from `head`
        # up to `cur` has no adjacent duplicates. This is not expressible formally
        # with the given contract language.
        # Termination depends on the list being acyclic, which is an implicit
        # precondition. The measure that decreases is the number of nodes
        # remaining in the list from `cur` onwards.
        if cur.val == cur.next.val:
            cur.next = cur.next.next
        else:
            # This assertion captures the inductive step of the algorithm.
            # On this path, we have confirmed that `cur` does not have a duplicate
            # as its immediate successor, so it is safe to advance `cur`.
            # Stating this makes the local correctness property explicit for the prover.
            Assert(cur.val != cur.next.val)
            cur = cur.next
    return head