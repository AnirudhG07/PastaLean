# Two performance patterns that must NOT be O(n²)/O(n):
# 1. `[x]*n` array-backing — a sieve does many `a[i]=v`; without Array backing each is an O(n) copy.
# 2. `bisect_left(range(...), key=f)` — must binary-search the range lazily, not materialize + map key.
from bisect import bisect_left


def count_primes(n: int) -> int:
    sieve = [True] * n
    ans = 0
    for i in range(2, n):
        if sieve[i]:
            ans += 1
            for j in range(i + i, n, i):
                sieve[j] = False
    return ans


def isqrt_via_bisect(num: int) -> int:
    # first x in [1, num+1) with x*x > num, minus 1  → floor(sqrt(num))
    return bisect_left(range(1, num + 1), num + 1, key=lambda x: x * x)


def main():
    print(count_primes(100))            # 25 primes below 100
    print(count_primes(1000))           # 168
    print(isqrt_via_bisect(24))         # 4  (4*4=16<=24, 5*5=25>24)
    print(isqrt_via_bisect(25))         # 5


if __name__ == "__main__":
    main()
