from contracts import *

def choose_num(x, y):
    """This function takes two positive numbers x and y and returns the
    biggest even integer number that is in the range [x, y] inclusive. If 
    there's no such number, then the function should return -1.

    For example:
    choose_num(12, 15) = 14
    choose_num(13, 12) = -1
    """
    # The result is either -1 (if no even number exists in [x,y])
    # or it is an even number in [x,y] and is the largest such number.
    # The "largest" property is captured by `Result() + 2 > y`, which means
    # the next even number is outside the range.
    Ensures((Result() == -1) or
            (Result() % 2 == 0 and x <= Result() <= y and Result() + 2 > y))

    if x > y:
        return -1
    Assert(x <= y)

    if x == y:
        return y if y % 2 == 0 else -1
    Assert(x < y)

    # From here, we know x < y
    if y % 2 == 0:
        return y
    else:
        # y is odd. We know x < y. For integers, this implies x <= y - 1.
        # This means y - 1, which is even, is guaranteed to be in the range [x, y].
        Assert(y % 2 != 0)
        Assert(x <= y - 1)
        return y - 1