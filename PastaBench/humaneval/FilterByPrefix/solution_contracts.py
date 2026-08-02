from contracts import *
from typing import List


def filter_by_prefix(strings: List[str], prefix: str) -> List[str]:
    """ Filter an input list of strings only for ones that start with a given prefix.
    >>> filter_by_prefix([], 'a')
    []
    >>> filter_by_prefix(['abc', 'bcd', 'cde', 'array'], 'a')
    ['abc', 'array']
    """
    Ensures(all(s.startswith(prefix) for s in Result()))
    Ensures(all(s in strings for s in Result()))
    Ensures(len(Result()) == len([s for s in strings if s.startswith(prefix)]))
    return list(filter(lambda x: x.startswith(prefix), strings))