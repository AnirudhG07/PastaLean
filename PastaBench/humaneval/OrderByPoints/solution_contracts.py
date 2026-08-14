from contracts import *
from typing import *


# Hoisted to module scope: it captures nothing from `order_by_points`, and a nested `def`
# would make the contracts below reference a name that is not yet bound.
def weight(x):
    x_list = list(str(x))
    if x_list[0] == "-":
        x_list = x_list[1:]
        x_list = list(map(int, x_list))
        x_list[0] = -x_list[0]
    else:
        x_list = list(map(int, x_list))
    return sum(x_list)


def order_by_points(nums: List[int]):
    """
    Write a function which sorts the given list of integers
    in ascending order according to the sum of their digits.
    Note: if there are several items with similar sum of their digits,
    order them based on their index in original list.

    For example:
    >>> order_by_points([1, 11, -1, -11, -12]) == [-1, -11, 1, -12, 11]
    >>> order_by_points([]) == []
    """
    Ensures(len(Result()) == len(nums))
    # The output is a permutation of the input: every value keeps its multiplicity.
    Ensures(all(Result().count(v) == nums.count(v) for v in nums))
    # The output is non-decreasing in digit weight (`weight` negates the leading digit of a
    # negative number, which is this problem's own convention).
    Ensures(all(weight(Result()[i]) <= weight(Result()[i + 1]) for i in range(len(Result()) - 1)))
    # Stability, stated exactly: within any one weight class the output preserves the input
    # order. Together with the two facts above this pins the result down completely.
    Ensures(all(
        [y for y in Result() if weight(y) == weight(x)]
        == [y for y in nums if weight(y) == weight(x)]
        for x in nums
    ))

    return sorted(nums, key=weight)
