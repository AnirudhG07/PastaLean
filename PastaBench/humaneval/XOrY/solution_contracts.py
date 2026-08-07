from contracts import *

def x_or_y(n, x, y):
    """A simple program which should return the value of x if n is 
    a prime number and should return the value of y otherwise.

    Examples:
    for x_or_y(7, 34, 12) == 34
    for x_or_y(15, 8, 5) == 5
    
    """
    # The point: the choice between x and y is governed exactly by primality of n, stated as
    # trial division over the full range(2, n) (no sqrt cutoff, no float reasoning). The
    # disjunctive form is deliberate: it stays correct when x == y.
    # No `Requires` on n — the recorded inputs include n < 0, which is simply "not prime".
    Ensures(
        (
            (n >= 2 and all(n % d != 0 for d in range(2, n))) and Result() == x
        ) or
        (
            not (n >= 2 and all(n % d != 0 for d in range(2, n))) and Result() == y
        )
    )

    def is_prime(a):
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))
    return x if is_prime(n) else y