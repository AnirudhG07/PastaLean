from contracts import *
from typing import List, Tuple
import math


def sum_product(numbers: List[int]) -> Tuple[int, int]:
    """ For a given list of integers, return a tuple consisting of a sum and a product of all the integers in a list.
    Empty sum should be equal to 0 and empty product should be equal to 1.
    >>> sum_product([])
    (0, 1)
    >>> sum_product([1, 2, 3, 4])
    (10, 24)
    """
    # The two exact folds ...
    Ensures(Result()[0] == sum(numbers))
    Ensures(Result()[1] == math.prod(numbers))
    # ... and the empty-input identities the problem calls out explicitly (0 for the empty sum,
    # 1 for the empty product — the neutral element of each operation).
    Ensures(len(numbers) > 0 or (Result()[0] == 0 and Result()[1] == 1))

    s, p = 0, 1
    # The for-each loop is expressed with an explicit index `i` via `enumerate`
    # to enable writing the index-style invariants required for verification.
    for i, number in enumerate(numbers):
        Invariant(0 <= i <= len(numbers))
        Invariant(s == sum(numbers[:i]))
        Invariant(p == math.prod(numbers[:i]))
        s += number
        p *= number

    Assert(s == sum(numbers))
    Assert(p == math.prod(numbers))
    return s, p