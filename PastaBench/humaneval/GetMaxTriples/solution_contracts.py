from typing import *
from contracts import *


def get_max_triples(n: int):
    """
    You are given a positive integer n. You have to create an integer array a of length n.
        For each i (1 ≤ i ≤ n), the value of a[i] = i * i - i + 1.
        Return the number of triples (a[i], a[j], a[k]) of a where i < j < k,
    and a[i] + a[j] + a[k] is a multiple of 3.

    Example :
        Input: n = 5
        Output: 1
        Explanation:
        a = [1, 3, 7, 13, 21]
        The only valid triple is (1, 7, 13).
    """
    Requires(n > 0)
    # a[i] = i*i - i + 1 is ≡ 0 mod 3 exactly when i ≡ 2 mod 3, and ≡ 1 mod 3 otherwise — no
    # residue-2 class exists. So a valid triple takes all three from the 0-class or all three
    # from the 1-class, giving C(c0,3) + C(c1,3) with c0 = (n+1)//3 and c1 = n - c0.
    # Each product of three consecutive integers is divisible by 6, so the equality is exact.
    # (It also covers the n <= 2 early return, where both binomials vanish and Result() is False.)
    Ensures(
        6 * Result()
        == (n - (n + 1) // 3) * (n - (n + 1) // 3 - 1) * (n - (n + 1) // 3 - 2)
        + ((n + 1) // 3) * ((n + 1) // 3 - 1) * ((n + 1) // 3 - 2)
    )
    Ensures(Result() >= 0)

    if n <= 2:
        return False
    one_cnt = 1 + (n - 2) // 3 * 2 + (n - 2) % 3
    zero_cnt = n - one_cnt
    return one_cnt * (one_cnt - 1) * (one_cnt - 2) // 6 + zero_cnt * (zero_cnt - 1) * (zero_cnt - 2) // 6
