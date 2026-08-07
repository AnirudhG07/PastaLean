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
    # THE POINT, as an exhaustive case split. Empty result EXACTLY when no even value exists (the
    # second disjunct forces a length-2 result otherwise). Otherwise the pair is
    # [value, index] where the value is even, is <= every even value in arr (minimality), sits at
    # that index, and no EARLIER index carries it (first among ties).
    Ensures(
        (Result() == [] and all(val % 2 == 1 for val in arr))
        or (
            len(Result()) == 2
            and Result()[0] % 2 == 0
            and 0 <= Result()[1]
            and Result()[1] < len(arr)
            and arr[Result()[1]] == Result()[0]
            and all(x >= Result()[0] for x in arr if x % 2 == 0)
            and all(arr[k] != Result()[0] for k in range(Result()[1]))
        )
    )

    if all(val % 2 == 1 for val in arr): return []
    min_even = min(filter(lambda x: x % 2 == 0, arr))
    # `min_even` is an even element of arr and no even element is smaller — the value half of the
    # postcondition, established before the scan that supplies the index half.
    Assert(min_even % 2 == 0)
    Assert(min_even in arr)
    Assert(all(x >= min_even for x in arr if x % 2 == 0))
    for i in range(len(arr)):
        Invariant(0 <= i)
        Invariant(i <= len(arr))
        # Still scanning means every earlier position missed, so the first hit is the smallest index.
        Invariant(all(arr[j] != min_even for j in range(i)))
        if arr[i] == min_even:
            return [min_even, i]
