from contracts import *


def get_odd_collatz(n):
    """
    Given a positive integer n, return a sorted list that has the odd numbers in collatz sequence.

    The Collatz conjecture is a conjecture in mathematics that concerns a sequence defined
    as follows: start with any positive integer n. Then each term is obtained from the 
    previous term as follows: if the previous term is even, the next term is one half of 
    the previous term. If the previous term is odd, the next term is 3 times the previous
    term plus 1. The conjecture is that no matter what value of n, the sequence will always reach 1.

    Note: 
        1. Collatz(1) is [1].
        2. returned list sorted in increasing order.

    For example:
    get_odd_collatz(5) returns [1, 5] # The collatz sequence for 5 is [5, 16, 8, 4, 2, 1], so the odd numbers are only 1, and 5.
    """
    Requires(n > 0)
    Ensures(1 in Result())
    # `v`, not `x`: `x` is a local the loop mutates, and a comprehension binder sharing that
    # name is a trap on the Lean side.
    Ensures(all(v % 2 == 1 for v in Result()))
    Ensures(all(v >= 1 for v in Result()))
    Ensures(all(Result()[i] <= Result()[i + 1] for i in range(len(Result()) - 1)))
    # 1 is in the list, everything is >= 1 and the list is sorted, so 1 is the head.
    Ensures(len(Result()) >= 1 and Result()[0] == 1)
    # The trajectory starts at n, so an odd input is itself a member — the only entry point
    # into the sequence that can be named without unrolling it.
    Ensures(n % 2 == 0 or n in Result())

    ans, x = [], n
    # Termination is equivalent to the Collatz conjecture, an open problem.
    # The contracts below establish partial correctness: if the loop terminates,
    # the result has the specified properties.
    while x != 1:
        Invariant(x > 0)
        Invariant(all(y % 2 == 1 for y in ans))
        Invariant(all(y >= 1 for y in ans))
        # An odd `n` is recorded on the very first pass; before that pass `x` is still `n`.
        Invariant(n % 2 == 0 or x == n or n in ans)
        if x % 2 == 1: ans.append(x)
        x = x // 2 if x % 2 == 0 else x * 3 + 1
    
    Assert(x == 1)
    ans.append(1)
    
    Assert(1 in ans)
    Assert(all(y % 2 == 1 for y in ans))
    
    return sorted(ans)