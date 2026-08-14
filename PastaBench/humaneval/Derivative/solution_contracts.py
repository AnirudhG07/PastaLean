from contracts import *


def derivative(xs: list):
    """ xs represent coefficients of a polynomial.
    xs[0] + xs[1] * x + xs[2] * x^2 + ....
     Return derivative of this polynomial in the same form.
    >>> derivative([3, 1, 2, 4, 5])
    [1, 4, 12, 20]
    >>> derivative([1, 2, 3])
    [2, 6]
    """
    Ensures(len(Result()) == max(0, len(xs) - 1))
    Ensures(all(Result()[j] == xs[j + 1] * (j + 1) for j in range(len(Result()))))

    return [xs[i] * i for i in range(1, len(xs))]