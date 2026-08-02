from typing import *
from contracts import *

def unique_digits(x: List[int]):
    """Given a list of positive integers x. return a sorted list of all 
    elements that hasn't any even digit.

    Note: Returned list should be sorted in increasing order.
    
    For example:
    >>> unique_digits([15, 33, 1422, 1])
    [1, 15, 33]
    >>> unique_digits([152, 323, 1422, 10])
    []
    """


    def judge(num):
        Requires(num >= 0)
        Ensures(Result() == all(int(c) % 2 != 0 for c in str(num)))

        for ch in str(num):
            if int(ch) % 2 == 0:
                return False
        
        Assert(all(int(c) % 2 != 0 for c in str(num)))
        return True

    Requires(all(e >= 0 for e in x))
    # The result must be sorted in non-decreasing order.
    Ensures(all(Result()[i] <= Result()[i + 1] for i in range(len(Result()) - 1)))
    # The multiset of the result must be exactly the multiset of elements from x
    # for which `judge` returns true. This covers filtering and duplicate preservation.
    Ensures(all(Result().count(v) == (x.count(v) if judge(v) else 0) for v in set(x)))
    
    return sorted(list(filter(judge, x)))