from contracts import *


def strlen(string: str) -> int:
    """ Return length of given string
    >>> strlen('')
    0
    >>> strlen('abc')
    3
    """
    Ensures(Result() >= 0)
    Ensures(Result() == len(string))

    return len(string)