from contracts import *


def fizz_buzz(n: int):
    """Return the number of times the digit 7 appears in integers less than n which are divisible by 11 or 13.
    >>> fizz_buzz(50)
    0
    >>> fizz_buzz(78)
    2
    >>> fizz_buzz(79)
    3
    """
    Requires(n >= 0)
    Ensures(Result() >= 0)

    cnt = 0
    for i in range(n):
        Invariant(0 <= i)
        Invariant(i <= n)
        Invariant(cnt >= 0)
        Decreases(n - i)

        if i % 11 == 0 or i % 13 == 0:
            # The result of len() is always non-negative. This is sufficient
            # to prove that `cnt` itself is always non-negative.
            cnt += len(list(filter(lambda c: c == "7", str(i))))
    return cnt