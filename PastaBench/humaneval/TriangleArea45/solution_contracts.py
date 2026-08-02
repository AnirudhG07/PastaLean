from contracts import *


def triangle_area(a, h):
    """Given length of a side and high return area for a triangle.
    >>> triangle_area(5, 3)
    7.5
    """
    Requires(a >= 0)
    Requires(h >= 0)
    Ensures(2 * Result() == a * h)

    return a * h / 2