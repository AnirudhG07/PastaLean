from contracts import *
from typing import List


def concatenate(strings: List[str]) -> str:
    """ Concatenate list of strings into a single string
    >>> concatenate([])
    ''
    >>> concatenate(['a', 'b', 'c'])
    'abc'
    """
    Ensures(len(Result()) == sum(len(s) for s in strings))
    return "".join(strings)