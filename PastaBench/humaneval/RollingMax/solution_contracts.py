from contracts import *
from typing import List


def rolling_max(numbers: List[int]) -> List[int]:
    """ From a given list of integers, generate a list of rolling maximum element found until given moment
    in the sequence.
    >>> rolling_max([1, 2, 3, 2, 3, 4, 2])
    [1, 2, 3, 3, 3, 4, 4]
    """
    Ensures(len(Result()) == len(numbers))
    # The core functional specification: each element of the result list is the
    # maximum of the corresponding prefix of the input list.
    Ensures(
        all(Result()[i] == max(numbers[: i + 1]) for i in range(len(numbers)))
    )

    return [max(numbers[:(i+1)]) for i in range(len(numbers))]