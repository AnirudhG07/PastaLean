from contracts import *

def circular_shift(x, shift):
    """Circular shift the digits of the integer x, shift the digits right by shift
    and return the result as a string.
    If shift > number of digits, return digits reversed.
    >>> circular_shift(12, 1)
    "21"
    >>> circular_shift(12, 2)
    "12"
    """
    Requires(x >= 0)
    Requires(shift >= 0)
    Ensures(len(Result()) == len(str(x)))

    s = str(x)
    # The length of the string representation of a non-negative integer is at least 1.
    # This is a crucial precondition for the modulo operation `shift % len(s)`.
    Assert(len(s) >= 1)

    if shift > len(s): return s[::-1]
    
    # On this path, the condition of the `if` is false, establishing this bound.
    Assert(shift <= len(s))
    
    shift %= len(s)
    
    if shift == 0:
        return s
    else:
        # From `shift %= len(s)`, we know `0 <= shift < len(s)`.
        # From the `if`, we know `shift != 0`.
        # This establishes the bounds needed for the slicing operation to be valid.
        Assert(0 < shift)
        Assert(shift < len(s))
        return s[len(s) - shift:] + s[:len(s) - shift]