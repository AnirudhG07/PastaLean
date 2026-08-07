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


    Requires(all(e >= 0 for e in x))
    # 1. The result is sorted in non-decreasing order.
    Ensures(all(Result()[i] <= Result()[i + 1] for i in range(len(Result()) - 1)))
    # 2. Soundness: every element kept has only odd digits.
    Ensures(all(all(int(c) % 2 != 0 for c in str(v)) for v in Result()))
    # 3. Exactness (sub-multiset + completeness): for every value occurring in x, the result keeps
    #    all of its occurrences when its digits are all odd, and none of them otherwise. The
    #    `judge` predicate is inlined rather than called — a nested helper is not in scope for the
    #    postcondition.
    Ensures(all(
        Result().count(v) == (x.count(v) if all(int(c) % 2 != 0 for c in str(v)) else 0)
        for v in set(x)
    ))

    def judge(num):
        Requires(num >= 0)

        for ch in str(num):
            if int(ch) % 2 == 0:
                return False

        Assert(all(int(c) % 2 != 0 for c in str(num)))
        return True

    return sorted(list(filter(judge, x)))