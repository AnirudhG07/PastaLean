from contracts import *

def digits(n: int):
    """Given a positive integer n, return the product of the odd digits.
    Return 0 if all digits are even.
    For example:
    digits(1)  == 1
    digits(4)  == 0
    digits(235) == 15
    """
    Requires(n >= 0)
    # A product of odd digits is itself odd; if there are none the result is 0. So the result is
    # always either 0 or odd — never a nonzero even. (The naive "n even ⇒ result 0" is false: n=12
    # is even yet has the odd digit 1, so digits(12) = 1.)
    Ensures(Result() == 0 or Result() % 2 == 1)
    has_odd, prod = False, 1
    for ch in str(n):
        if int(ch) % 2 == 1:
            has_odd = True
            prod *= int(ch)
    return 0 if not has_odd else prod

