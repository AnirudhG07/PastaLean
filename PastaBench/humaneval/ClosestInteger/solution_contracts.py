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
    # The result must be an integer within 0.5 of the float value of the input.
    Ensures(abs(float(value) - Result()) <= 0.5)
    # Tie-breaking rule: for half-integers, round away from zero, meaning
    # the result's magnitude is strictly greater than the input's.
    Ensures(
        not (abs(float(value) - int(float(value))) == 0.5 and float(value) != 0.0)
        or abs(Result()) > abs(float(value))
    )

    def rounding(val):
        # This helper's contract mirrors the parent's, generalized to any float.
        # This allows the verifier to prove the properties of the helper, then
        # apply them to the specific call in the parent function.
        Ensures(abs(val - Result()) <= 0.5)
        Ensures(
            not (abs(val - int(val)) == 0.5 and val != 0.0)
            or abs(Result()) > abs(val)
        )

        if abs(val - int(val)) != 0.5:
            Assert(abs(val - int(val)) != 0.5)
            # Not a half-integer, so standard rounding gives the unique closest integer.
            return round(val)

        # This point is only reached if the number is a half-integer.
        Assert(abs(val - int(val)) == 0.5)

        if val > 0:
            Assert(val > 0)
            # Positive half-integer: round up, away from zero.
            return int(val) + 1
        else:
            Assert(val <= 0)
            # Since `abs(val - int(val)) == 0.5`, `val` cannot be 0.
            Assert(val < 0.0)
            # Negative half-integer: round down, away from zero.
            return int(val) - 1

    return rounding(float(value))