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
    Ensures(-1 <= Result() < len(arr))
    # THE POINT (part 1): a returned index really is a descent, arr[i] < arr[i-1].
    Ensures(Result() == -1 or (1 <= Result() and arr[Result()] < arr[Result() - 1]))
    # THE POINT (part 2): it is the LARGEST such index — nothing above it is a descent.
    Ensures(Result() == -1 or all(arr[j] >= arr[j - 1] for j in range(Result() + 1, len(arr))))
    # ... and -1 is returned only when the array has no descent at all.
    Ensures(Result() != -1 or all(arr[j] >= arr[j - 1] for j in range(1, len(arr))))

    for i in range(len(arr) - 1, 0, -1):
        Invariant(1 <= i)
        Invariant(i < len(arr))
        # Accumulator carrying the maximality clause: every index already scanned
        # (strictly above i) was not a descent.
        Invariant(all(arr[j] >= arr[j - 1] for j in range(i + 1, len(arr))))
        Decreases(i)

        if not (arr[i] >= arr[i - 1]):
            return i
    return -1
