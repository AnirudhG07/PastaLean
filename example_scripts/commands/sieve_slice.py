# An array-backed `[True]*n` sieve whose slice result is assigned to a new variable.
# Regression: the slice-result binder (`head`) must follow the source's backing — in the run twin
# `sieve` is `Array Bool`, so `sieve[:k]` is `Array Bool`, and stamping `head : List Bool` would clash
# (`PySlice (Array β)` returns `Array β`). Also checks `[x]*n` under a heap cell emits `pyListRepeat`
# a bare list, not an `(← allocM …)` ref.
def count_primes(n: int) -> int:
    sieve = [True] * n
    ans = 0
    for i in range(2, n):
        if sieve[i]:
            ans += 1
            for j in range(i + i, n, i):
                sieve[j] = False
    head = sieve[: n // 2]
    return ans + len(head)


def main():
    print(count_primes(50))
