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
    # The point: the answer is exactly "some prefix sum is negative".
    Ensures(
        Result() == any(sum(operations[: k + 1]) < 0 for k in range(len(operations)))
    )
    # Contrapositive form, so the False case carries content too: on a False answer every
    # prefix balance stayed non-negative.
    Ensures(
        Result() or all(sum(operations[: k + 1]) >= 0 for k in range(len(operations)))
    )

    account = 0
    for operation in operations:
        # Reaching the top of the body means no prefix has gone negative yet — the balance
        # here IS the running prefix sum, so this is the loop's half of the postcondition.
        Invariant(account >= 0)
        # A prefix sum can never exceed the total of the deposits.
        Invariant(account <= sum(x for x in operations if x > 0))
        account += operation
        if account < 0:
            return True
    return False