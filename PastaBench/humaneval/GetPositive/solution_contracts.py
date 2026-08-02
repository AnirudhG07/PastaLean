from contracts import *


def get_positive(l: list[int]):
    """Return only positive numbers in the list.
    >>> get_positive([-1, 2, -4, 5, 6])
    [2, 5, 6]
    >>> get_positive([5, 3, -5, 2, -3, 3, 9, 0, 123, 1, -10])
    [5, 3, 2, 3, 9, 123, 1]
    """
    Ensures(all(x > 0 for x in Result()))
    Ensures(all(x in l for x in Result()))
    return list(filter(lambda x: x > 0, l))