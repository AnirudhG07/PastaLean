from contracts import *
from typing import List, Optional


def longest(strings: List[str]) -> Optional[str]:
    """ Out of list of strings, return the longest one. Return the first one in case of multiple
    strings of the same length. Return None in case the input list is empty.
    >>> longest([])

    >>> longest(['a', 'b', 'c'])
    'a'
    >>> longest(['a', 'bb', 'ccc'])
    'ccc'
    """
    # The result is None exactly when the input list is empty.
    Ensures((Result() is None) == (len(strings) == 0))
    # A non-None result is one of the input strings, and it is of maximal length.
    Ensures(Result() is None or Result() in strings)
    Ensures(Result() is None or all(len(s) <= len(Result()) for s in strings))

    if not strings:
        return None

    maxlen = max(len(x) for x in strings)
    for s in strings:
        if len(s) == maxlen:
            return s
