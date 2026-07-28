from contracts import *

def kInversePairs(n: int, k: int) -> int:
    Requires(n >= 0)
    Requires(k >= 0)
    Ensures(0 <= Result() < 1000000007)
    mod = 10 ** 9 + 7
    f = [1] + [0] * k
    s = [0] * (k + 2)
    for i in range(1, n + 1):
        for j in range(1, k + 1):
            f[j] = (s[j + 1] - s[max(0, j - (i - 1))]) % mod
        for j in range(1, k + 2):
            s[j] = (s[j - 1] + f[j - 1]) % mod
    return f[k]