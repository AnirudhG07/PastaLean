from contracts import *
from typing import List


def mean_absolute_deviation(numbers: List[float]) -> float:
    """ For a given list of input numbers, calculate Mean Absolute Deviation
    around the mean of this dataset.
    Mean Absolute Deviation is the average absolute difference between each
    element and a centerpoint (mean in this case):
    MAD = average | x - x_mean |
    >>> mean_absolute_deviation([1.0, 2.0, 3.0, 4.0])
    1.0
    """
    Requires(len(numbers) > 0)
    # The defining identity, stated division-free on the *outer* average: n times the answer is
    # the total absolute deviation. (The inner mean keeps its division — clearing it too, to
    # `n*n*Result() == sum(abs(n*x - sum(numbers)))`, is NOT float-exact and was rejected.)
    Ensures(len(numbers) * Result()
            == sum(abs(v - sum(numbers) / len(numbers)) for v in numbers))
    # Sharp two-sided bound: a deviation is never negative and never exceeds the spread.
    Ensures(Result() >= 0.0)
    Ensures(Result() <= max(numbers) - min(numbers))

    mean = sum(numbers) / len(numbers)
    return sum(abs(x - mean) for x in numbers) / len(numbers)