from contracts import *


def change_base(x: int, base: int):
    """Change numerical base of input number x to base.
    return string representation after the conversion.
    base numbers are less than 10.
    >>> change_base(8, 3)
    '22'
    >>> change_base(8, 2)
    '1000'
    >>> change_base(7, 2)
    '111'
    """
    Requires(x >= 0)
    # The algorithm using str() is only correct for bases where digits are single characters.
    # The docstring and implementation imply a base between 2 and 9.
    Requires(2 <= base < 10)

    # The postcondition captures the two main behaviors of the function:
    # 1. If the input is 0, the output is "0".
    # 2. If the input is positive, the output is a non-empty string.
    # This assumes `x` in `Ensures` refers to the initial value of the parameter.
    Ensures((x == 0 and Result() == "0") or (x > 0 and Result() != ""))

    if x == 0:
        return "0"

    # After the guard, we know x is not 0. Given the precondition x >= 0, x must be positive.
    Assert(x > 0)
    ret = ""
    while x != 0:
        # The loop condition `x != 0` and prior state `x >= 0` ensure `x > 0` on entry.
        Invariant(x > 0)
        # Since base >= 2, integer division of a positive x strictly decreases x
        # while keeping it non-negative, ensuring termination.
        Decreases(x)
        ret = str(x % base) + ret
        x //= base
    
    # Because the initial x was > 0, the loop must have run at least once.
    # Therefore, 'ret' cannot be empty. This is the key fact to prove the postcondition.
    Assert(ret != "")
    return ret