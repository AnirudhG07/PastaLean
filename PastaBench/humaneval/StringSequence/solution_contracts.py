from contracts import *


def string_sequence(n: int) -> str:
    """ Return a string containing space-delimited numbers starting from 0 upto n inclusive.
    >>> string_sequence(0)
    '0'
    >>> string_sequence(5)
    '0 1 2 3 4 5'
    """

    Requires(n >= 0)
    # THE POINT: the result splits into exactly n+1 space-delimited fields, and field i is
    # the decimal rendering of i. Together these pin the string completely (the join has no
    # separator ambiguity because no field contains a space).
    Ensures(len(Result().split(' ')) == n + 1)
    Ensures(Result().split(' ') == [str(i) for i in range(n + 1)])

    return " ".join(map(str, range(n + 1)))