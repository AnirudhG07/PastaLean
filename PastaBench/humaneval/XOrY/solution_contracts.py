from contracts import *

def x_or_y(n, x, y):
    """A simple program which should return the value of x if n is 
    a prime number and should return the value of y otherwise.

    Examples:
    for x_or_y(7, 34, 12) == 34
    for x_or_y(15, 8, 5) == 5
    
    """
    Requires(n >= 0)
    Ensures(
        (
            (n >= 2 and all(n % d != 0 for d in range(2, int(n**0.5) + 1))) and Result() == x
        ) or
        (
            not (n >= 2 and all(n % d != 0 for d in range(2, int(n**0.5) + 1))) and Result() == y
        )
    )

    def is_prime(a):
        Requires(a >= 0)
        Ensures(Result() == (a >= 2 and all(a % d != 0 for d in range(2, int(a**0.5) + 1))))
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))
    return x if is_prime(n) else y