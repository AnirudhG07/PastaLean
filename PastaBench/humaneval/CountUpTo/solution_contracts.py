from typing import *
from contracts import *

def count_up_to(n: int):
    """Implement a function that takes an non-negative integer and returns an array of the first n
    integers that are prime numbers and less than n.
    """
    Requires(n >= 0)
    # THE POINT: the answer is drawn from the window {2, ..., n-1} — the sieve only ever appends
    # its own loop counter, which runs over exactly that range — and since at most one number is
    # appended per counter value, the list can never be longer than n.
    Ensures(len(Result()) <= n)
    Ensures(all(2 <= p for p in Result()))
    Ensures(all(p < n for p in Result()))
    ans = []
    isprime = [True] * (n + 1)
    for i in range(2, n):
        Invariant(2 <= i)
        Invariant(i <= n)
        Invariant(len(isprime) == n + 1)
        # At most one append per counter value.
        Invariant(len(ans) <= i)
        # Everything appended so far was a counter value already passed.
        Invariant(all(2 <= p for p in ans))
        Invariant(all(p < i for p in ans))
        if isprime[i]:
            ans.append(i)
            for j in range(i + i, n, i):
                # Index bound for `isprime[j]`.
                Invariant(2 <= j)
                Invariant(j < n)
                isprime[j] = False
    return ans
