import math
from contracts import *


def prod_signs(arr):
    """
    You are given an array arr of integers and you need to return
    sum of magnitudes of integers multiplied by product of all signs
    of each number in the array, represented by 1, -1 or 0.
    Note: return None for empty arr.

    Example:
    >>> prod_signs([1, 2, 2, -4]) == -9
    >>> prod_signs([0, 1]) == 0
    >>> prod_signs([]) == None
    """
    # The Ensures contract captures the full specification of the function across its three return paths.
    # The conditional expression (A if C else B) is pure and suitable for specifications.
    Ensures(Result() == (
        None if arr == [] else
        0 if 0 in arr else
        sum(abs(x) for x in arr) * math.prod(x // abs(x) for x in arr)
    ))

    if arr == []: return None

    if 0 in arr: return 0
    
    # After the guards, we can assert that the array is non-empty and contains no zeros.
    # This is a crucial fact for the safety of the division in the loop.
    Assert(arr != [])
    Assert(0 not in arr)
    
    s, sgn = 0, 1
    # To write index-style invariants that capture the function's core logic, we use
    # enumerate to track the loop index `i`. This does not change runtime behavior.
    for i, x in enumerate(arr):
        Invariant(0 <= i <= len(arr))
        # s accumulates the sum of absolute values of the prefix arr[:i].
        Invariant(s == sum(abs(y) for y in arr[:i]))
        # sgn accumulates the product of signs of the prefix arr[:i].
        # The verifier is assumed to have a model for the pure function math.prod.
        Invariant(sgn == math.prod(y // abs(y) for y in arr[:i]))
        # Weaker, but helpful linear/simple properties for the solver.
        Invariant(s >= 0)
        Invariant(sgn == 1 or sgn == -1)

        s += abs(x)
        sgn *= (x // abs(x))
    
    # After the loop, the invariants hold for i == len(arr). These assertions bridge
    # the loop's final state to the function's postcondition.
    Assert(s == sum(abs(x) for x in arr))
    Assert(sgn == math.prod(x // abs(x) for x in arr))
    
    return s * sgn