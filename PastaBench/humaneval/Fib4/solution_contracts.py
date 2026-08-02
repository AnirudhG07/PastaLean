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
    # The postcondition states that the function correctly implements the spec.
    # We assume `fib4(k)` in a contract refers to the pure mathematical function.
    Ensures(
        (n == 0 and Result() == 0) or
        (n == 1 and Result() == 0) or
        (n == 2 and Result() == 2) or
        (n == 3 and Result() == 0) or
        (n >= 4 and Result() == fib4(n - 1) + fib4(n - 2) + fib4(n - 3) + fib4(n - 4))
    )

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
        # Establish that the initial state corresponds to the spec's base cases,
        # which forms the base case for the loop invariant.
        Assert(a == fib4(0))
        Assert(b == fib4(1))
        Assert(c == fib4(2))
        Assert(d == fib4(3))

        for i in range(4, n + 1):
            # The loop counter is bounded. This is crucial for proving memory safety
            # if we were indexing, and helps reason about termination and the state.
            Invariant(4 <= i)
            Invariant(i <= n + 1)
            # The core invariant: the variables track the four preceding fib4 numbers,
            # allowing the next one to be computed.
            Invariant(a == fib4(i - 4))
            Invariant(b == fib4(i - 3))
            Invariant(c == fib4(i - 2))
            Invariant(d == fib4(i - 1))
            # Termination is obvious for a `range` loop, but for more complex loops,
            # a `Decreases` clause would be necessary.
            Decreases(n + 1 - i)

            a, b, c, d = b, c, d, a + b + c + d
        
        # When the loop terminates, the loop counter i is conceptually n + 1.
        # The invariant, evaluated at this exit value, gives us the desired property.
        # Specifically, `d` now holds the value for `fib4((n+1)-1)`, which is `fib4(n)`.
        Assert(d == fib4(n - 1) + fib4(n - 2) + fib4(n - 3) + fib4(n - 4))
        return d