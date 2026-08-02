from contracts import *

def can_arrange(arr):
    """Create a function which returns the largest index of an element which
    is not greater than or equal to the element immediately preceding it. If
    no such element exists then return -1. The given array will not contain
    duplicate values.

    Examples:
    can_arrange([1,2,4,3,5]) = 3
    can_arrange([1,2,3]) = -1
    """
    # The docstring guarantees that the input array has no duplicate values.
    Requires(len(set(arr)) == len(arr))

    # The result is always a valid index in the range [1, len(arr)-1] or -1.
    Ensures(-1 <= Result() < len(arr))
    # If an index is returned (i.e., Result() > 0), it must point to a
    # "descent" where arr[i] < arr[i-1]. If -1 is returned, this condition
    # is vacuously true. This captures the core correctness property.
    Ensures(Result() <= 0 or arr[Result()] < arr[Result() - 1])


    for i in range(len(arr) - 1, 0, -1):
        # Invariant: i is always a valid index for accessing arr[i] and arr[i-1].
        # The loop runs for i from len(arr)-1 down to 1, so 1 <= i < len(arr).
        Invariant(1 <= i < len(arr))
        # The loop terminates because i strictly decreases and is bounded by 0.
        Decreases(i)

        if not (arr[i] >= arr[i - 1]):
            return i
    return -1