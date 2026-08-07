from contracts import *


def fibfib(n: int):
    """The FibFib number sequence is a sequence similar to the Fibbonacci sequnece that's defined as follows:
    fibfib(0) == 0
    fibfib(1) == 0
    fibfib(2) == 1
    fibfib(n) == fibfib(n-1) + fibfib(n-2) + fibfib(n-3).
    Please write a function to efficiently compute the n-th element of the fibfib number sequence.
    >>> fibfib(1)
    0
    >>> fibfib(5)
    4
    >>> fibfib(8)
    24
    """
    Requires(n >= 0)
    # THE POINT: a growth bound. The rolling window (a, b, c) = (F(i-3), F(i-2), F(i-1)) is
    # non-negative, and because the three-term sum is always at least one more than the leading
    # entry's own bound, the leading entry outgrows the index: fibfib(n) >= n - 2 for every n.
    # (It is tight at n = 3 and n = 4, so it is the strongest linear bound available.)
    Ensures(Result() >= n - 2)
    Ensures(Result() >= 0)

    if n == 0 or n == 1:
        return 0
    elif n == 2:
        return 1

    Assert(n >= 3)
    a, b, c = 0, 0, 1
    for i in range(3, n + 1):
        Invariant(3 <= i)
        Invariant(i <= n + 1)
        Invariant(a >= 0)
        Invariant(b >= 0)
        Invariant(c >= 0)
        # The window never dies out ...
        Invariant(b + c >= 1)
        # ... the leading entry already beats i - 3 ...
        Invariant(c >= i - 3)
        # ... and the value it is about to become beats i - 2, which is what makes the previous
        # invariant inductive (and, at exit i = n + 1, gives the Ensures).
        Invariant(a + b + c >= i - 2)
        a, b, c = b, c, a + b + c

    Assert(c >= n - 2)
    Assert(c >= 0)
    return c
