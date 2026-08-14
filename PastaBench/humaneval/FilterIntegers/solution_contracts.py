from contracts import *
from typing import List, Any


def filter_integers(values: List[Any]) -> List[int]:
    """ Filter given list of any python values only for integers
    >>> filter_integers(['a', 3.14, 5])
    [5]
    >>> filter_integers([1, 2, 3, 'abc', {}, []])
    [1, 2, 3]
    """
    Ensures(all(type(x) == int for x in Result()))
    Ensures(all(x in values for x in Result()))
    Ensures(len(Result()) == sum(1 for v in values if type(v) == int))

    return list(filter(lambda x: type(x) == int, values))