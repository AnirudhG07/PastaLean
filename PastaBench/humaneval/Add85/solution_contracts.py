from contracts import *

def add(lst):
    """Given a non-empty list of integers lst. add the even elements that are at odd indices..


    Examples:
        add([4, 2, 6, 7]) ==> 2 
    """
    # The docstring specifies a non-empty list.
    # The code would work for an empty list, but we follow the stated intent.
    Requires(len(lst) > 0)
    # The function sums even numbers, so the result must also be even.
    Ensures(Result() % 2 == 0)

    s = 0
    # The loop iterates through odd indices i = 1, 3, 5, ... up to len(lst).
    for i in range(1, len(lst), 2):
        # The running sum `s` is always even because we only add even numbers to it.
        # This invariant is the key to proving the postcondition.
        Invariant(s % 2 == 0)
        # The loop index `i` is always a valid index for `lst`.
        # These bounds are crucial for proving memory safety of `lst[i]`.
        Invariant(1 <= i)
        Invariant(i < len(lst))
        # By construction of range(1, ..., 2), the index `i` is always odd.
        Invariant(i % 2 == 1)

        if lst[i] % 2 == 0:
            s += lst[i]
            
    # After the loop, the invariant still holds for the final sum.
    # This provides a direct bridge to the Ensures clause.
    Assert(s % 2 == 0)
    return s