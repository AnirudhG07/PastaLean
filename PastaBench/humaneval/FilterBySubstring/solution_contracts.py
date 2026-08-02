from typing import List
from contracts import *


def filter_by_substring(strings: List[str], substring: str) -> List[str]:
    """ Filter an input list of strings only for ones that contain given substring
    >>> filter_by_substring([], 'a')
    []
    >>> filter_by_substring(['abc', 'bacd', 'cde', 'array'], 'a')
    ['abc', 'bacd', 'array']
    """
    Ensures(
        # All elements in the result must contain the substring and must have been in the input list.
        all(substring in s and s in strings for s in Result()) and
        # All elements from the input list that contain the substring must be in the result.
        all(s in Result() for s in strings if substring in s)
    )
    return list(filter(lambda s: substring in s, strings))