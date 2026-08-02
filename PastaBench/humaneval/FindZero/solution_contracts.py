import math
from contracts import *


def poly(xs: list, x: float):
    """
    Evaluates polynomial with coefficients xs at point x.
    return xs[0] + xs[1] * x + xs[1] * x^2 + .... xs[n] * x^n
    """
    return sum([coeff * math.pow(x, i) for i, coeff in enumerate(xs)])


def find_zero(xs: list):
    """ xs are coefficients of a polynomial.
    find_zero find x such that poly(x) = 0.
    find_zero returns only only zero point, even if there are many.
    Moreover, find_zero only takes list xs having even number of coefficients
    and largest non zero coefficient as it guarantees
    a solution.
    >>> round(find_zero([1, 2]), 2) # f(x) = 1 + 2x
    -0.5
    >>> round(find_zero([-6, 11, -6, 1]), 2) # (x - 1) * (x - 2) * (x - 3) = -6 + 11x - 6x^2 + x^3
    1.0
    """
    Requires(len(xs) >= 2)
    Requires(len(xs) % 2 == 0)
    Requires(xs[len(xs) - 1] != 0.0)
    Ensures(abs(poly(xs, Result())) < 1e-5)


    dxs = [xs[i] * i for i in range(1, len(xs))]
    Assert(len(dxs) == len(xs) - 1)
    def func(x):
        return poly(xs, x)
    def derivative(x):
        return poly(dxs, x)
    
    x, tol = 0, 1e-5
    for _ in range(1000):
        fx = func(x)
        dfx = derivative(x)
        if abs(fx) < tol:
            Assert(abs(poly(xs, x)) < 1e-5)
            break
        x = x - fx / dfx

    Assert(abs(poly(xs, x)) < 1e-5)
    return x