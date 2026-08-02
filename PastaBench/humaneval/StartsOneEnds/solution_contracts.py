from contracts import *

def starts_one_ends(n):
    """
    Given a positive integer n, return the count of the numbers of n-digit
    positive integers that start or end with 1.
    """
    Requires(n >= 1)
    Ensures((n == 1 and Result() == 1) or (n > 1 and Result() == 18 * 10**(n - 2)))

    if n == 1:
        return 1
    
    Assert(n > 1)
    return 18 * 10 ** (n - 2)