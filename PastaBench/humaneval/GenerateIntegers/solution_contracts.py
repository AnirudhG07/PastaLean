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
    # Soundness: every element is an even single digit inside the (unordered) range.
    Ensures(all(x % 2 == 0 for x in Result()))
    Ensures(all(0 <= x < 10 for x in Result()))
    Ensures(all(min(a, b) <= x <= max(a, b) for x in Result()))
    # Strictly ascending, and complete — together these pin the answer to exactly one list.
    Ensures(all(Result()[i] < Result()[i + 1] for i in range(len(Result()) - 1)))
    Ensures(len(Result())
            == len([i for i in range(min(a, b), min(max(a, b) + 1, 10)) if i % 2 == 0]))

    if a > b: a, b = b, a
    return [i for i in range(a, min(b + 1, 10)) if i % 2 == 0]
