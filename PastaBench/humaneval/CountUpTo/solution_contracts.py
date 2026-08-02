from typing import *
from contracts import *

def count_up_to(n: int):
    """Implement a function that takes an non-negative integer and returns an array of the first n
    integers that are prime numbers and less than n.
    """
    Requires(n >= 0)
    # The primes below n are a subset of {2, …, n-1}, so there can be at most n of them: the length
    # of the result is bounded by n. (Invariant: at most one number is appended per iteration.)
    Ensures(len(Result()) <= n)
    ans = []
    isprime = [True] * (n + 1)
    for i in range(2, n):
        Invariant(len(ans) <= i)
        if isprime[i]:
            ans.append(i)
            for j in range(i + i, n, i):
                isprime[j] = False
    return ans
