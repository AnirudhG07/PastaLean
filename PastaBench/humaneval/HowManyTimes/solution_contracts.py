from contracts import *


def how_many_times(string: str, substring: str) -> int:
    """ Find how many times a given substring can be found in the original string. Count overlaping cases.
    >>> how_many_times('', 'a')
    0
    >>> how_many_times('aaa', 'a')
    3
    >>> how_many_times('aaaa', 'aa')
    3
    """
    # The notion of "finding" an empty substring is ambiguous.
    # The standard `str.count('')` has surprising behavior (`len(s) + 1`).
    # This implementation would return `len(s)`. We restrict to the common case.
    Requires(len(substring) > 0)

    # The point of the contracts is to prove that the result is a sensible count:
    # it's non-negative and bounded by the number of possible start positions.
    Ensures(0 <= Result())
    Ensures(Result() <= len(string))

    occurences = 0
    for i in range(len(string)):
        # Standard invariants for the loop counter `i` in `range(n)`.
        Invariant(0 <= i)
        Invariant(i <= len(string))
        # Accumulator-style invariants for the running count `occurences`.
        # The count is always non-negative.
        Invariant(0 <= occurences)
        # At each step `i`, we have checked `i` positions (0 to i-1),
        # so the number of occurrences cannot be more than `i`.
        Invariant(occurences <= i)

        if string[i:].startswith(substring):
            occurences += 1

    # After the loop, the invariants hold with the final value of the counter (`i` is effectively `len(string)`).
    # This assertion bridges the invariants to the postconditions.
    Assert(0 <= occurences)
    Assert(occurences <= len(string))
    return occurences