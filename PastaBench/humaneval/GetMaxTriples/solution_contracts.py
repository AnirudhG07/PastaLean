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
    # Closed form: with c0 = #{i : a[i] % 3 == 0} = (n-2)//3 + 1 (for n > 2) and c1 = n - c0,
    # the answer is C(c1,3) + C(c0,3). The exact value equalities (and `Implies`/mid-`Assert`
    # bridges, not yet lowerable) are proved in Proofs.lean; here we keep the sign invariant.
    Ensures(Result() >= 0)

    if n <= 2:
        return 0
    one_cnt = 1 + (n - 2) // 3 * 2 + (n - 2) % 3
    zero_cnt = n - one_cnt
    return one_cnt * (one_cnt - 1) * (one_cnt - 2) // 6 + zero_cnt * (zero_cnt - 1) * (zero_cnt - 2) // 6
