from contracts import *


def median(l: list):
    """Return median of elements in the list l.
    >>> median([3, 1, 2, 4, 5])
    3
    >>> median([-10, 4, 6, 1000, 10, 20])
    8.0
    """

    Requires(len(l) > 0)
    # THE POINT: the result is the middle of the SORTED list — stated against sorted(l), which the
    # code never inspects positionally. Odd length: exactly the middle element.
    Ensures(len(l) % 2 == 0 or Result() == sorted(l)[len(l) // 2])
    # Even length: the mean of the two middle elements, written division-free.
    Ensures(len(l) % 2 == 1 or 2 * Result() == sorted(l)[len(l) // 2 - 1] + sorted(l)[len(l) // 2])
    # The median always sits between the extremes: at least one element is <= it and one is >= it.
    Ensures(any(x <= Result() for x in l) and any(x >= Result() for x in l))

    sorted_l = sorted(l)
    Assert(len(sorted_l) == len(l))

    if len(l) % 2 == 1:
        Assert(len(l) % 2 == 1)
        # The precondition `len(l) > 0` ensures `len(l) // 2` is a valid index.
        return sorted_l[len(l) // 2]
    else:
        Assert(len(l) % 2 == 0)
        # The precondition `len(l) > 0` and this branch condition `len(l) % 2 == 0`
        # together imply `len(l) >= 2`, which ensures both indices are valid.
        return (sorted_l[len(l) // 2 - 1] + sorted_l[len(l) // 2]) / 2