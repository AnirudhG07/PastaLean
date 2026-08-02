from contracts import *


# This function is for specification purposes only.
# It is assumed to be interpreted as a pure logical function by the verifier.
def fibfib_spec(k: int) -> int:
    Requires(k >= 0)
    if k == 0:
        return 0
    elif k == 1:
        return 0
    elif k == 2:
        return 1
    else:
        return fibfib_spec(k - 1) + fibfib_spec(k - 2) + fibfib_spec(k - 3)


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
    Ensures(Result() == fibfib_spec(n))

    if n == 0 or n == 1:
        return 0
    elif n == 2:
        return 1
    
    Assert(n >= 3)
    a, b, c = 0, 0, 1
    for i in range(3, n + 1):
        Invariant(3 <= i and i <= n + 1)
        Invariant(a == fibfib_spec(i - 3))
        Invariant(b == fibfib_spec(i - 2))
        Invariant(c == fibfib_spec(i - 1))
        a, b, c = b, c, a + b + c

    Assert(c == fibfib_spec(n))
    return c