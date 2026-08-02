from contracts import *


def incr_list(l: list[int]) -> list[int]:
    """Return list with elements incremented by 1.
    >>> incr_list([1, 2, 3])
    [2, 3, 4]
    >>> incr_list([5, 3, 5, 2, 3, 3, 9, 0, 123])
    [6, 4, 6, 3, 4, 4, 10, 1, 124]
    """
    Ensures(Result() == [x + 1 for x in l])

    return [x + 1 for x in l]