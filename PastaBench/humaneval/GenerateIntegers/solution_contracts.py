from contracts import *


def generate_integers(a, b):
    """
    Given two positive integers a and b, return the even digits between a
    and b, in ascending order.

    For example:
    generate_integers(2, 8) => [2, 4, 6, 8]
    generate_integers(8, 2) => [2, 4, 6, 8]
    generate_integers(10, 14) => []
    """
    Requires(a > 0)
    Requires(b > 0)
    Ensures(forall(Result(), lambda x: x % 2 == 0))
    Ensures(forall(Result(), lambda x: x < 10))
    Ensures(forall(Result(), lambda x: min(a, b) <= x <= max(a, b)))
    Ensures(forall(range(len(Result()) - 1), lambda i: Result()[i] < Result()[i+1]))


    if a > b: a, b = b, a
    return [i for i in range(a, min(b + 1, 10)) if i % 2 == 0]