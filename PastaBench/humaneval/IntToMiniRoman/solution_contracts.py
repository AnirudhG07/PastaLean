from contracts import *


def int_to_mini_roman(number):
    """
    Given a positive integer, obtain its roman numeral equivalent as a string,
    and return it in lowercase.
    Restrictions: 1 <= num <= 1000

    Examples:
    >>> int_to_mini_roman(19) == 'xix'
    >>> int_to_mini_roman(152) == 'clii'
    >>> int_to_mini_roman(426) == 'cdxxvi'
    """
    Requires(1 <= number and number <= 1000)


    m = ["", "m"]
    c = ["", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm"]
    x = ["", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc"]
    i = ["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"]

    Assert(0 <= number // 1000 < len(m))
    thousands = m[number // 1000]

    Assert(0 <= (number % 1000) // 100 < len(c))
    hundreds = c[(number % 1000) // 100]

    Assert(0 <= (number % 100) // 10 < len(x))
    tens = x[(number % 100) // 10]

    Assert(0 <= number % 10 < len(i))
    ones = i[number % 10]
    return thousands + hundreds + tens + ones