from contracts import *
from typing import List


def has_close_elements(numbers: List[float], threshold: float) -> bool:
    """ Check if in given list of numbers, are any two numbers closer to each other than
    given threshold.
    >>> has_close_elements([1.0, 2.0, 3.0], 0.5)
    False
    >>> has_close_elements([1.0, 2.8, 3.0, 4.0, 5.0, 2.0], 0.3)
    True
    """
    Requires(threshold > 0.0)
    Ensures(
        Result() == any(
            sorted(numbers)[i + 1] - sorted(numbers)[i] < threshold
            for i in range(len(numbers) - 1)
        )
    )

    sorted_numbers = sorted(numbers)
    for i in range(len(sorted_numbers) - 1):
        Invariant(0 <= i)
        Invariant(i <= len(sorted_numbers) - 1)
        Invariant(
            all(sorted_numbers[k + 1] - sorted_numbers[k] >= threshold for k in range(i))
        )
        Decreases(len(sorted_numbers) - 1 - i)

        if sorted_numbers[i + 1] - sorted_numbers[i] < threshold:
            return True

    Assert(
        all(
            sorted_numbers[k + 1] - sorted_numbers[k] >= threshold
            for k in range(len(sorted_numbers) - 1)
        )
    )
    return False