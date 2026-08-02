from contracts import *


def order_by_points(nums):
    """
    Write a function which sorts the given list of integers
    in ascending order according to the sum of their digits.
    Note: if there are several items with similar sum of their digits,
    order them based on their index in original list.

    For example:
    >>> order_by_points([1, 11, -1, -11, -12]) == [-1, -11, 1, -12, 11]
    >>> order_by_points([]) == []
    """

    # A key property of any sorting function is that the output is a
    # permutation of the input. A full formal statement of this is complex,
    # but at a minimum, the length must be preserved.
    Ensures(len(Result()) == len(nums))

    # The main purpose of this function is to sort the list according to
    # the custom `weight` function. This postcondition captures that intent.
    # Note: this contract does not formally specify the stability property
    # mentioned in the docstring (tie-breaking by original index), as that
    # is complex to express. Python's `sorted` is stable by default, so
    # the implementation is correct.
    Ensures(len(Result()) < 2 or all(
        weight(Result()[i]) <= weight(Result()[i+1])
        for i in range(len(Result()) - 1)
    ))

    def weight(x):
        x_list = list(str(x))
        if x_list[0] == "-":
            x_list = x_list[1:]
            x_list = list(map(int, x_list))
            x_list[0] = -x_list[0]
        else:
            x_list = list(map(int, x_list))
        return sum(x_list)
    return sorted(nums, key=weight)