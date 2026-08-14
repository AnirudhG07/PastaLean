from contracts import *

def any_int(x, y, z):
    '''
    Create a function that takes 3 numbers.
    Returns true if one of the numbers is equal to the sum of the other two, and all numbers are integers.
    Returns false in any other cases.

    Examples
    any_int(5, 2, 7) ➞ True

    any_int(3, 2, 2) ➞ False

    any_int(3, -2, 1) ➞ True

    any_int(3.6, -2.2, 2) ➞ False



    '''
    # THE POINT: the result is exactly the conjunction of the two stated requirements —
    # all three arguments are integers AND one of them is the sum of the other two.
    # Both halves matter: on (1.5, 5, 3.5) the sum condition holds yet the answer is False.
    Ensures(Result() == (type(x) == int and type(y) == int and type(z) == int
                         and (x == y + z or y == x + z or z == x + y)))

    if type(x) != int or type(y) != int or type(z) != int: return False

    Assert(type(x) == int and type(y) == int and type(z) == int)
    return x == y + z or y == x + z or z == y + x
