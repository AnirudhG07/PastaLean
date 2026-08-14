from contracts import *
from typing import *

def exchange(lst1: List[int], lst2: List[int]):
    """In this problem, you will implement a function that takes two lists of numbers,
    and determines whether it is possible to perform an exchange of elements
    between them to make lst1 a list of only even numbers.
    There is no limit on the number of exchanged elements between lst1 and lst2.
    If it is possible to exchange elements between the lst1 and lst2 to make
    all the elements of lst1 to be even, return "YES".
    Otherwise, return "NO".
    For example:
    exchange([1, 2, 3, 4], [1, 2, 3, 4]) => "YES"
    exchange([1, 2, 3, 4], [1, 5, 3, 4]) => "NO"
    It is assumed that the input lists will be non-empty.
    """
    Requires(len(lst1) > 0)
    Requires(len(lst2) > 0)
    # The function's purpose is to check if there are enough even numbers in lst2
    # to replace all odd numbers in lst1. This is the core correctness condition.
    Ensures((Result() == "YES") == (len([x for x in lst1 if x % 2 == 1]) <= len([x for x in lst2 if x % 2 == 0])))

    cnt_odd = len(list(filter(lambda x: x % 2 == 1, lst1)))
    # Bridge the implementation (which uses filter/lambda) to the declarative
    # specification in the Ensures clause.
    Assert(cnt_odd == len([x for x in lst1 if x % 2 == 1]))
    Assert(0 <= cnt_odd)
    Assert(cnt_odd <= len(lst1))

    cnt_even = len(list(filter(lambda x: x % 2 == 0, lst2)))
    Assert(cnt_even == len([x for x in lst2 if x % 2 == 0]))
    Assert(0 <= cnt_even)
    Assert(cnt_even <= len(lst2))

    return "YES" if cnt_odd <= cnt_even else "NO"