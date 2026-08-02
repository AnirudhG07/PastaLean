from typing import *
from contracts import *

def is_sorted(lst: List[int]):
    '''
    Given a list of numbers, return whether or not they are sorted
    in ascending order. If list has more than 1 duplicate of the same
    number, return False. Assume no negative numbers and only integers.

    Examples
    is_sorted([5]) ➞ True
    is_sorted([1, 2, 3, 4, 5]) ➞ True
    is_sorted([1, 3, 2, 4, 5]) ➞ False
    is_sorted([1, 2, 3, 4, 5, 6]) ➞ True
    is_sorted([1, 2, 3, 4, 5, 6, 7]) ➞ True
    is_sorted([1, 3, 2, 4, 5, 6, 7]) ➞ False
    is_sorted([1, 2, 2, 3, 3, 4]) ➞ True
    is_sorted([1, 2, 2, 2, 3, 4]) ➞ False
    '''
    Requires(all(x >= 0 for x in lst))
    Ensures(Result() == (all(lst.count(x) <= 2 for x in set(lst)) and lst == sorted(lst)))

    count = dict()
    for x in lst:
        Invariant(all(c <= 2 for c in count.values()))
        Invariant(all(k >= 0 for k in count.keys()))
        if x not in count: count[x] = 0
        count[x] += 1
        if count[x] > 2: return False
    
    Assert(all(lst.count(x) <= 2 for x in set(lst)))
    return lst == sorted(lst)