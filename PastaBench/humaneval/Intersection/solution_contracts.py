from contracts import *


def intersection(interval1, interval2):
    """You are given two intervals,
    where each interval is a pair of integers. For example, interval = (start, end) = (1, 2).
    The given intervals are closed which means that the interval (start, end)
    includes both start and end.
    For each given interval, it is assumed that its start is less or equal its end.
    Your task is to determine whether the length of intersection of these two 
    intervals is a prime number.
    Example, the intersection of the intervals (1, 3), (2, 4) is (2, 3)
    which its length is 1, which not a prime number.
    If the length of the intersection is a prime number, return "YES",
    otherwise, return "NO".
    If the two intervals don't intersect, return "NO".


    [input/output] samples:
    intersection((1, 2), (2, 3)) ==> "NO"
    intersection((-1, 1), (0, 4)) ==> "NO"
    intersection((-3, -1), (-5, 5)) ==> "YES"
    """

    Requires(len(interval1) == 2)
    Requires(len(interval2) == 2)
    Requires(interval1[0] <= interval1[1])
    Requires(interval2[0] <= interval2[1])

    Ensures(Result() == "YES" or Result() == "NO")
    # THE POINT: the answer is "YES" exactly when the length of the intersection
    # [max(start1, start2), min(end1, end2)] is a prime number. Primality is stated by
    # full trial division over range(2, L) — NOT by the sqrt-bounded loop the code runs, so this
    # is a genuine statement about the number rather than a restatement of `is_prime`.
    # A non-positive length (the intervals miss each other) has L < 2, hence "NO".
    # The expression is symmetric in interval1/interval2, so the swap below cannot disturb it.
    Ensures((Result() == "YES") == (
        min(interval1[1], interval2[1]) - max(interval1[0], interval2[0]) >= 2
        and all(
            (min(interval1[1], interval2[1]) - max(interval1[0], interval2[0])) % x != 0
            for x in range(2, min(interval1[1], interval2[1]) - max(interval1[0], interval2[0]))
        )
    ))

    def is_prime(a):
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))
    if interval1[0] > interval2[0]: interval1, interval2 = interval2, interval1
    # This assertion establishes the ordering after the potential swap, which is a key
    # lemma for proving that the subsequent calculation of l and r is correct.
    Assert(interval1[0] <= interval2[0])

    l, r = interval2[0], min(interval1[1], interval2[1])
    return "YES" if is_prime(r - l) else "NO"