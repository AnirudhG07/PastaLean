from contracts import *
from typing import List


def intersperse(numbers: List[int], delimeter: int) -> List[int]:
    """ Insert a number 'delimeter' between every two consecutive elements of input list `numbers'
    >>> intersperse([], 4)
    []
    >>> intersperse([1, 2, 3], 4)
    [1, 4, 2, 4, 3]
    """
    Ensures(len(Result()) == max(0, 2 * len(numbers) - 1))

    res = []
    for i in range(len(numbers)):
        Invariant(0 <= i)
        Invariant(i <= len(numbers))
        # At the start of each iteration i, the previous i iterations have each
        # added two elements (a number and a delimiter), resulting in a list of length 2*i.
        # This holds because the delimiter is only omitted on the *final* iteration,
        # which has no subsequent iteration to check this invariant.
        Invariant(len(res) == 2 * i)

        res.append(numbers[i])
        if i != len(numbers) - 1:
            res.append(delimeter)

    # After the loop, the invariant for i=n plus the action of the last iteration (i=n-1)
    # establish the final length.
    Assert(len(res) == max(0, 2 * len(numbers) - 1))
    return res