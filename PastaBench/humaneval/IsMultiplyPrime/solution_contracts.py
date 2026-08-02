from contracts import *

def is_multiply_prime(a):
    """Write a function that returns true if the given number is the multiplication of 3 prime numbers
    and false otherwise.
    Knowing that (a) is less then 100. 
    Example:
    is_multiply_prime(30) == True
    30 = 2 * 3 * 5
    """
    Requires(0 <= a < 100)

    if a <= 1: return False
    Assert(2 <= a < 100)

    isprime = [True] * (a + 1)
    Assert(len(isprime) == a + 1)
    for i in range(2, a + 1):
        Invariant(2 <= i <= a + 1)
        if isprime[i]:
            for j in range(i + i, a + 1, i):
                Invariant(i + i <= j <= a)
                Invariant(j % i == 0)
                # This invariant is crucial for proving memory safety of `isprime[j] = False`.
                Invariant(0 <= j < len(isprime))
                isprime[j] = False

    cnt, tmp = 0, a
    for i in range(2, a + 1):
        Invariant(2 <= i <= a + 1)
        Invariant(cnt >= 0)
        # `tmp` holds the unfactored part of the original `a`. It must be >= 1.
        Invariant(1 <= tmp <= a)

        while isprime[i] and tmp % i == 0:
            Decreases(tmp)
            Invariant(tmp >= 1)
            Invariant(cnt >= 0)
            
            tmp //= i
            cnt += 1

    # The correctness of the function relies on `a` being fully factored.
    # This means the remainder `tmp` must be 1, which implies `cnt` holds the total
    # number of prime factors of the original `a`.
    Assert(tmp == 1)

    return cnt == 3