from contracts import *
from typing import List


def below_zero(operations: List[int]) -> bool:
    """ You're given a list of deposit and withdrawal operations on a bank account that starts with
    zero balance. Your task is to detect if at any point the balance of account fallls below zero, and
    at that point function should return True. Otherwise it should return False.
    >>> below_zero([1, 2, 3])
    False
    >>> below_zero([1, 2, -4, 5])
    True
    """
    Ensures(
        Result() == any(sum(operations[: k + 1]) < 0 for k in range(len(operations)))
    )

    account = 0
    for operation in operations:
        # The invariant is that the account balance, which represents the sum
        # of the operations processed so far, must be non-negative for the
        # loop to continue.
        Invariant(account >= 0)
        account += operation
        if account < 0:
            return True
    return False