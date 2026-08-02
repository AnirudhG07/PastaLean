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

    # Helper function is defined before contracts to be in scope for them.
    # This is a behavior-preserving reordering of statements.
    def is_prime(a):
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))

    Requires(len(interval1) == 2)
    Requires(len(interval2) == 2)
    Requires(interval1[0] <= interval1[1])
    Requires(interval2[0] <= interval2[1])

    Ensures(Result() == "YES" or Result() == "NO")
    # The point of the function: the result string reflects the primality of the intersection's length.
    # The intersection is [max(start1, start2), min(end1, end2)].
    # Its length is min(end1, end2) - max(start1, start2).
    # is_prime returns False for non-positive lengths, correctly handling empty intersections.
    Ensures((Result() == "YES") == is_prime(min(interval1[1], interval2[1]) - max(interval1[0], interval2[0])))

    if interval1[0] > interval2[0]: interval1, interval2 = interval2, interval1
    # This assertion establishes the ordering after the potential swap, which is a key
    # lemma for proving that the subsequent calculation of l and r is correct.
    Assert(interval1[0] <= interval2[0])

    l, r = interval2[0], min(interval1[1], interval2[1])
    return "YES" if is_prime(r - l) else "NO"