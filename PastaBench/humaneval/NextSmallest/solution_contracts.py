from contracts import *


def next_smallest(lst: list[int]):
    """
    You are given a list of integers.
    Write a function next_smallest() that returns the 2nd smallest element of the list.
    Return None if there is no such element.
    
    next_smallest([1, 2, 3, 4, 5]) == 2
    next_smallest([5, 1, 4, 3, 2]) == 2
    next_smallest([]) == None
    next_smallest([1, 1]) == None
    """
    # When a 2nd-smallest exists, it is characterised by three facts that together say
    # "the smallest value strictly above the minimum":
    # 1. it really occurs in the input,
    Ensures(Result() is None or Result() in lst)
    # 2. it is strictly above the minimum,
    Ensures(len(lst) == 0 or Result() is None or Result() > min(lst))
    # 3. and NOTHING in the input lies strictly between the minimum and it — this maximality
    #    clause is what rules out any larger element and pins the answer down uniquely.
    Ensures(len(lst) == 0 or Result() is None or
            all(y <= min(lst) or y >= Result() for y in lst))
    # Conversely, None is returned only when there is nothing above the minimum at all.
    Ensures(len(lst) == 0 or Result() is not None or all(y == min(lst) for y in lst))

    if len(lst) <= 1:
        return None
    Assert(len(lst) > 1)

    sorted_list = sorted(lst)
    Assert(len(sorted_list) > 1)
    # Bridge sorted_list back to the input, and identify its head as the minimum, so the
    # returned element can be related to `lst` and `min(lst)` in the Ensures.
    Assert(sorted(sorted_list) == sorted(lst))
    Assert(sorted_list[0] == min(lst))

    for x in sorted_list:
        # Accumulator-style. The scan is ascending, so the body is only ever reached while `x`
        # is still the minimum, plus exactly once more with the first value above it. Hence the
        # current candidate is always an input element, never below the minimum, and — the
        # moment it stops being the minimum — has nothing of `lst` strictly beneath it.
        Invariant(x in lst)
        Invariant(x >= min(lst))
        Invariant(x == min(lst) or all(y <= min(lst) or y >= x for y in lst))
        if x != sorted_list[0]:
            # The first element in a sorted list that is not the minimum is, by
            # definition, the second-smallest unique element.
            return x

    # If the loop completes, it means the `if` condition was never true.
    # For a sorted list, this implies all elements are identical.
    Assert(sorted_list[0] == sorted_list[-1])
    # The function implicitly returns None here.