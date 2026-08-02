from contracts import *


def sort_even(l: list):
    """This function takes a list l and returns a list l' such that
    l' is identical to l in the odd indicies, while its values at the even indicies are equal
    to the values of the even indicies of l, but sorted.
    >>> sort_even([1, 2, 3])
    [1, 2, 3]
    >>> sort_even([5, 6, 3, 4])
    [3, 6, 5, 4]
    """
    Ensures(len(Result()) == len(l))
    # The elements at odd indices are unchanged.
    Ensures(all(Result()[i] == l[i] for i in range(len(l)) if i % 2 != 0))
    # The elements at even indices are the sorted version of the original even-indexed elements.
    # This single postcondition captures both the sorting and the multiset-preservation properties.
    Ensures(
        [Result()[i] for i in range(len(l)) if i % 2 == 0]
        == sorted([l[i] for i in range(len(l)) if i % 2 == 0])
    )

    even = [l[i] for i in range(len(l)) if i % 2 == 0]
    even.sort()

    # Bridge assertion: after the in-place sort, `even` now holds the sorted
    # list of the original even-indexed elements. This is the key property
    # used by the final list comprehension to build the result.
    Assert(even == sorted([l[i] for i in range(len(l)) if i % 2 == 0]))

    return [even[i // 2] if i % 2 == 0 else l[i] for i in range(len(l))]