from contracts import *


def pairs_sum_to_zero(l):
    """
    pairs_sum_to_zero takes a list of integers as an input.
    it returns True if there are two distinct elements in the list that
    sum to zero, and False otherwise.
    >>> pairs_sum_to_zero([1, 3, 5, 0])
    False
    >>> pairs_sum_to_zero([1, 3, -2, 1])
    False
    >>> pairs_sum_to_zero([1, 2, 3, 7])
    False
    >>> pairs_sum_to_zero([2, 4, -5, 3, 5, 7])
    True
    >>> pairs_sum_to_zero([1])
    False
    """
    # THE POINT: an exact iff with "two DISTINCT positions sum to zero". The distinctness is the
    # whole content — a lone 0 must NOT count, while [0, 0] must.
    Ensures(Result() == any(
        any(i != j and l[i] + l[j] == 0 for j in range(len(l)))
        for i in range(len(l))
    ))
    # Same property phrased over values instead of index pairs: some element's negation occurs
    # somewhere else in the list. Equivalent only because the index exclusion is done correctly.
    Ensures(Result() == any(-l[i] in l[:i] + l[i + 1:] for i in range(len(l))))
    # A witness needs two positions, so a list shorter than 2 can never answer True.
    Ensures(len(l) >= 2 or Result() == False)

    for i in range(len(l)):
        # No pair drawn entirely from the first `i` outer positions summed to zero, else we returned.
        Invariant(0 <= i)
        Invariant(i <= len(l))
        Invariant(not any(
            any(a != b and l[a] + l[b] == 0 for b in range(len(l)))
            for a in range(i)
        ))
        for j in range(len(l)):
            Invariant(0 <= j)
            Invariant(j <= len(l))
            Invariant(not any(i != b and l[i] + l[b] == 0 for b in range(j)))
            if i != j and l[i] + l[j] == 0:
                return True
    return False
