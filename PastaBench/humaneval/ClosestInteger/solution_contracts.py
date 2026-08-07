from contracts import *


def closest_integer(value):
    '''
    Create a function that takes a value (string) representing a number
    and returns the closest integer to it. If the number is equidistant
    from two integers, round it away from zero.

    Examples
    >>> closest_integer("10")
    10
    >>> closest_integer("15.3")
    15

    Note:
    Rounding away from zero means that if the given number is equidistant
    from two integers, the one you should return is the one that is the
    farthest from zero. For example closest_integer("14.5") should
    return 15 and closest_integer("-14.5") should return -15.
    '''
    # THE POINT (1): the answer is an integer no further than half a unit from the number — that
    # is what "closest integer" means, and it is the only thing that makes the answer unique off
    # the ties.
    Ensures(abs(float(value) - Result()) <= 0.5)
    # THE POINT (2): the tie-breaking rule, stated exactly. At an exact .5 the answer is the
    # integer *away from zero*, so its magnitude is precisely half a unit larger than the input's
    # — not merely "larger". This pins down which of the two candidates is returned.
    Ensures(
        abs(float(value) - int(float(value))) != 0.5
        or abs(Result()) == abs(float(value)) + 0.5
    )

    def rounding(val):
        if abs(val - int(val)) != 0.5:
            # Off a tie, `round` is the unique nearest integer.
            return round(val)

        # Only exact half-integers reach here, so `val` is never 0.
        if val > 0:
            Assert(abs(int(val) + 1) == abs(val) + 0.5)
            return int(val) + 1
        else:
            Assert(val < 0.0)
            # `int` truncates toward zero, so `int(val) - 1` steps away from zero.
            Assert(abs(int(val) - 1) == abs(val) + 0.5)
            return int(val) - 1

    return rounding(float(value))
