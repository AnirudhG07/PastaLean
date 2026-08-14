from contracts import *


def sort_array(array):
    """
    Given an array of non-negative integers, return a copy of the given array after sorting,
    you will sort the given array in ascending order if the sum( first index value, last index value) is odd,
    or sort it in descending order if the sum( first index value, last index value) is even.

    Note:
    * don't change the given array.

    Examples:
    * sort_array([]) => []
    * sort_array([5]) => [5]
    * sort_array([2, 4, 3, 0, 1, 5]) => [0, 1, 2, 3, 4, 5]
    * sort_array([2, 4, 3, 0, 1, 5, 6]) => [6, 5, 4, 3, 2, 1, 0]
    """
    # 1-2. The result is a permutation of the input (same length, same multiset).
    Ensures(len(Result()) == len(array))
    Ensures(sorted(Result()) == sorted(array))
    # 3. Odd endpoint-sum (or empty input) => ascending.
    Ensures(len(array) == 0 or (array[0] + array[-1]) % 2 == 0
            or all(Result()[j] <= Result()[j + 1] for j in range(len(Result()) - 1)))
    # 4. Even endpoint-sum => descending.
    Ensures(len(array) == 0 or (array[0] + array[-1]) % 2 == 1
            or all(Result()[j] >= Result()[j + 1] for j in range(len(Result()) - 1)))

    if array == []: return []
    return sorted(array, reverse=(array[0]+array[-1]) % 2 == 0)
