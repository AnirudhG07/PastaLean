from contracts import *
from typing import *
from bisect import *


def fullBloomFlowers(flowers: List[List[int]], people: List[int]) -> List[int]:
    """
    For each person, calculates the number of flowers that are in full bloom at the time
    of the person's arrival. A flower is in bloom if the arrival time is between its
    start and end bloom times, inclusive.
    """
    Requires(all(len(f) == 2 for f in flowers))
    Requires(all(f[0] <= f[1] for f in flowers))

    Ensures(len(Result()) == len(people))
    # THE POINT: The i-th result is the count of flowers whose bloom interval [start, end]
    # contains the i-th person's arrival time. This is the definitional property.
    Ensures(
        Result()
        == [sum(1 for f in flowers if f[0] <= p and p <= f[1]) for p in people]
    )

    start, end = (sorted((a for a, _ in flowers)), sorted((b for _, b in flowers)))
    return [bisect_right(start, p) - bisect_left(end, p) for p in people]