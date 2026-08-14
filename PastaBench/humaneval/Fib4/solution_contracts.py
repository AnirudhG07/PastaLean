from contracts import *


def fib4(n: int):
    """The Fib4 number sequence is a sequence similar to the Fibbonacci sequnece that's defined as follows:
    fib4(0) -> 0
    fib4(1) -> 0
    fib4(2) -> 2
    fib4(3) -> 0
    fib4(n) -> fib4(n-1) + fib4(n-2) + fib4(n-3) + fib4(n-4).
    Please write a function to efficiently compute the n-th element of the fib4 number sequence.  Do not use recursion.
    >>> fib4(5)
    4
    >>> fib4(6)
    8
    >>> fib4(7)
    14
    """

    Requires(n >= 0)
    # THE POINT: every fib4 term is even, and non-negative. The four seeds 0, 0, 2, 0 are, and the
    # recurrence only ever adds four such terms together, so evenness propagates forever — the
    # answer is never odd. This is the whole content of the rolling window, and (like the
    # gold-standard `Digits` parity spec) it is provable only by reasoning through the loop.
    Ensures(Result() % 2 == 0)
    Ensures(Result() >= 0)

    if n == 0:
        return 0
    elif n == 1:
        return 0
    elif n == 2:
        return 2
    elif n == 3:
        return 0
    else:
        Assert(n >= 4)
        a, b, c, d = 0, 0, 2, 0
        for i in range(4, n + 1):
            Invariant(4 <= i)
            Invariant(i <= n + 1)
            # The whole window stays even ...
            Invariant(a % 2 == 0)
            Invariant(b % 2 == 0)
            Invariant(c % 2 == 0)
            Invariant(d % 2 == 0)
            # ... and non-negative, so the four-term sum is too.
            Invariant(a >= 0)
            Invariant(b >= 0)
            Invariant(c >= 0)
            Invariant(d >= 0)
            Decreases(n + 1 - i)

            a, b, c, d = b, c, d, a + b + c + d

        Assert(d % 2 == 0)
        Assert(d >= 0)
        return d
