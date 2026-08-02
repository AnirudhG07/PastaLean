from contracts import *


def max_element(l: list):
    """Return maximum element in the list.
    >>> max_element([1, 2, 3])
    3
    >>> max_element([5, 3, -5, 2, -3, 3, 9, 0, 123, 1, -10])
    123
    """
    Requires(len(l) > 0)
    # The result is a member of the list and is greater-or-equal to every element.
    Ensures(Result() in l)
    Ensures(all(x <= Result() for x in l))

    return max(l)