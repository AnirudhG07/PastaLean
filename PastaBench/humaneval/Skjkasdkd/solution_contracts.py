from contracts import *


def skjkasdkd(lst):
    """You are given a list of integers.
    You need to find the largest prime value and return the sum of its digits.

    Examples:
    For lst = [0,3,2,1,3,5,7,4,5,5,5,2,181,32,4,32,3,2,32,324,4,3] the output should be 10
    For lst = [1,0,1,8,2,4597,2,1,3,40,1,2,1,2,4,2,5,1] the output should be 25
    For lst = [1,3,1,32,5107,34,83278,109,163,23,2323,32,30,1,9,3] the output should be 13
    For lst = [0,724,32,71,99,32,6,0,5,91,83,0,5,6] the output should be 11
    For lst = [0,81,12,3,1,21] the output should be 3
    For lst = [0,8,1,2,1,7] the output should be 7
    """
    # Without a prime in the list the loop falls through and the function returns nothing,
    # so there is no answer to specify.
    Requires(any(y >= 2 and all(y % d != 0 for d in range(2, y)) for y in lst))
    # THE POINT: the result is the decimal digit sum of a prime member of the list that
    # dominates every prime member of the list — i.e. of the largest prime in the list.
    # Primality is trial division: z >= 2 with no divisor in [2, z).
    Ensures(any(
        y >= 2
        and sum([int(ch) for ch in str(y)]) == Result()
        and all(y % d != 0 for d in range(2, y))
        and all(z <= y or z < 2 or any(z % d == 0 for d in range(2, z)) for z in lst)
        for y in lst))

    def is_prime(a):
        # No contract here: it is an inner helper whose specification is the primality
        # predicate spelled out at the call site below.
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))
    sorted_list = sorted(lst)[::-1]
    for x in sorted_list:
        if is_prime(x):
            # x really is prime (the sqrt-bounded test above agrees with full trial division) ...
            Assert(x >= 2 and all(x % d != 0 for d in range(2, x)))
            # ... and it is the largest prime in lst: scanning descending order, everything
            # strictly above x was rejected, so no z > x in lst is prime.
            Assert(all(z <= x or z < 2 or any(z % d == 0 for d in range(2, z)) for z in lst))
            return sum(map(lambda ch: int(ch), str(x)))

    # Unreachable under the precondition.
