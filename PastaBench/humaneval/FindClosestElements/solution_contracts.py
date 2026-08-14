from contracts import *
from typing import List, Tuple


def find_closest_elements(numbers: List[float]) -> Tuple[float, float]:
    """ From a supplied list of numbers (of length at least two) select and return two that are the closest to each
    other and return them in order (smaller number, larger number).
    >>> find_closest_elements([1.0, 2.0, 3.0, 4.0, 5.0, 2.2])
    (2.0, 2.2)
    >>> find_closest_elements([1.0, 2.0, 3.0, 4.0, 5.0, 2.0])
    (2.0, 2.0)
    """
    Requires(len(numbers) >= 2)
    # The returned pair should be ordered.
    Ensures(Result()[0] <= Result()[1])
    # The elements of the pair must be present in the (sorted) list.
    Ensures(Result()[0] in numbers)
    Ensures(Result()[1] in numbers)
    # The difference must be non-negative.
    Ensures(Result()[1] - Result()[0] >= 0.0)

    numbers.sort()
    min_diff = float("inf")
    min_pair = None
    for l, r in zip(numbers[:-1], numbers[1:]):
        # Invariants on the accumulator state.
        # `min_diff` is either infinity or the smallest non-negative difference found so far.
        Invariant(min_diff == float("inf") or min_diff >= 0.0)
        # `min_pair` is either None or a pair from the list reflecting the current `min_diff`.
        Invariant(min_pair is None or (min_pair[0] in numbers and min_pair[1] in numbers))
        Invariant(min_pair is None or min_pair[0] <= min_pair[1])
        Invariant(min_pair is None or min_pair[1] - min_pair[0] == min_diff)

        diff = r - l
        # After sorting, any adjacent pair (l, r) will have l <= r, so their difference is non-negative.
        # This fact is crucial for proving the invariant on min_diff is maintained.
        Assert(diff >= 0.0)
        if diff < min_diff:
            min_diff = diff
            min_pair = (l, r)
            
    # The precondition `len(numbers) >= 2` ensures the loop runs at least once,
    # so `min_pair` will be assigned a value.
    Assert(min_pair is not None)
    return min_pair