from contracts import *


def pluck(arr):
    """
    "Given an array representing a branch of a tree that has non-negative integer nodes
    your task is to pluck one of the nodes and return it.
    The plucked node should be the node with the smallest even value.
    If multiple nodes with the same smallest even value are found return the node that has smallest index.

    The plucked node should be returned in a list, [ smalest_value, its index ],
    If there are no even values or the given array is empty, return [].
    """
    Ensures(
        (Result() == [] and all(val % 2 == 1 for val in arr))
        or (
            len(Result()) == 2
            and Result()[0] % 2 == 0
            and Result()[0] == min(x for x in arr if x % 2 == 0)
            and arr[Result()[1]] == Result()[0]
            and all(arr[k] != Result()[0] for k in range(Result()[1]))
        )
    )

    if all(val % 2 == 1 for val in arr): return []
    min_even = min(filter(lambda x: x % 2 == 0, arr))
    for i in range(len(arr)):
        if arr[i] == min_even:
            return [min_even, i]
