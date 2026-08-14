from contracts import *


def unique(l: list):
    """Return sorted unique elements in a list
    >>> unique([5, 3, 5, 2, 3, 3, 9, 0, 123])
    [0, 2, 3, 5, 9, 123]
    """
    Ensures(set(Result()) == set(l))
    Ensures(all(Result()[i] < Result()[i+1] for i in range(len(Result()) - 1)))

    return sorted(set(l))