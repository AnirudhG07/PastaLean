from contracts import *


def string_sequence(n: int) -> str:
    """ Return a string containing space-delimited numbers starting from 0 upto n inclusive.
    >>> string_sequence(0)
    '0'
    >>> string_sequence(5)
    '0 1 2 3 4 5'
    """

    Requires(n >= 0)
    # The point of the function is to generate a sequence of n+1 numbers.
    # This is captured by asserting that if we split the resulting string by spaces,
    # we get a list of n+1 elements.
    Ensures(len(Result().split(' ')) == n + 1)

    return " ".join(map(str, range(n + 1)))