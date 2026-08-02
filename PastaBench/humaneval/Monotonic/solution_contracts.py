from contracts import *


def monotonic(l: list):
    """Return True is list elements are monotonically increasing or decreasing.
    >>> monotonic([1, 2, 4, 20])
    True
    >>> monotonic([1, 20, 4, 10])
    False
    >>> monotonic([4, 1, 0, -10])
    True
    """
    Ensures(Result() == (
        all(l[j] <= l[j + 1] for j in range(len(l) - 1)) or
        all(l[j] >= l[j + 1] for j in range(len(l) - 1))
    ))

    inc, dec = True, True
    for i in range(len(l) - 1):
        Invariant(0 <= i)
        Invariant(i <= len(l) - 1)
        Invariant(inc == all(l[j] <= l[j + 1] for j in range(i)))
        Invariant(dec == all(l[j] >= l[j + 1] for j in range(i)))

        if l[i] > l[i + 1]:
            inc = False
        if l[i] < l[i + 1]:
            dec = False
    return inc or dec