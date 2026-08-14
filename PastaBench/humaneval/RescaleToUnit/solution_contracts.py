from contracts import *
from typing import List


def rescale_to_unit(numbers: List[float]) -> List[float]:
    """ Given list of numbers (of at least two elements), apply a linear transform to that list,
    such that the smallest number will become 0 and the largest will become 1
    >>> rescale_to_unit([1.0, 2.0, 3.0, 4.0, 5.0])
    [0.0, 0.25, 0.5, 0.75, 1.0]
    """
    Requires(len(numbers) > 0)
    Requires(max(numbers) > min(numbers))
    # The point: the output is the affine image of the input that maps min -> 0 and max -> 1.
    # Stated over floats, so the two "hits the endpoint" facts and the affine law are given with a
    # tolerance: `(ma - mi) * (1 / (ma - mi))` is not exactly 1.0 in IEEE-754 (see the recorded
    # case [1.0, 2.0, 3.0, 4.88337557029465], whose maximum comes out as 0.9999999999999999).
    # `min -> 0` IS exact ((mi - mi) * k == 0.0), so no tolerance is needed there.
    Ensures(len(Result()) == len(numbers))
    Ensures(all(-1e-9 <= v <= 1.0 + 1e-9 for v in Result()))
    Ensures(any(v == 0.0 for v in Result()))
    Ensures(any(abs(v - 1.0) <= 1e-9 for v in Result()))
    # Affine relation, division-free: Result()[i] * (ma - mi) == numbers[i] - mi.
    Ensures(all(
        abs(Result()[i] * (max(numbers) - min(numbers)) - (numbers[i] - min(numbers)))
        <= 1e-9 * (max(numbers) - min(numbers))
        for i in range(len(numbers))
    ))

    ma, mi = max(numbers), min(numbers)
    Assert(ma > mi)
    k = 1 / (ma - mi)
    return list(map(lambda x: (x - mi) * k, numbers))