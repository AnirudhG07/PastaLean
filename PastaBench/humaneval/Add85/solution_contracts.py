from contracts import *

def add(lst):
    """Given a non-empty list of integers lst. add the even elements that are at odd indices..


    Examples:
        add([4, 2, 6, 7]) ==> 2
    """
    # The docstring specifies a non-empty list.
    Requires(len(lst) > 0)
    # THE POINT: only even elements are ever added, so the answer is even — never an odd number.
    # This is exactly the parity fact the accumulator invariant below establishes.
    Ensures(Result() % 2 == 0)

    s = 0
    # The loop visits the odd indices i = 1, 3, 5, ... below len(lst).
    for i in range(1, len(lst), 2):
        # The running sum stays even: it starts at 0 and only ever gains an even summand.
        Invariant(s % 2 == 0)
        # Index bounds, so `lst[i]` is well-defined.
        Invariant(1 <= i)
        Invariant(i < len(lst))
        # `range(1, _, 2)` only yields odd indices — the "at odd indices" half of the spec.
        Invariant(i % 2 == 1)

        if lst[i] % 2 == 0:
            s += lst[i]

    Assert(s % 2 == 0)
    return s
