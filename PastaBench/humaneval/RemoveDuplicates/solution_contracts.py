from contracts import *
from typing import List


def remove_duplicates(numbers: List[int]) -> List[int]:
    """ From a list of integers, remove all elements that occur more than once.
    Keep order of elements left the same as in the input.
    >>> remove_duplicates([1, 2, 3, 2, 4])
    [1, 3, 4]
    """
    # The result contains only unique elements. This follows from the property below,
    # but is a primary, user-visible property worth stating on its own.
    Ensures(len(set(Result())) == len(Result()))
    # An element is in the result if it occurred exactly once in the input.
    Ensures(all(numbers.count(x) == 1 for x in Result()))
    # Conversely, any element that occurred exactly once in the input is in the result.
    Ensures(all(x in Result() for x in numbers if numbers.count(x) == 1))

    num_cnt = dict()
    for number in numbers:
        if number not in num_cnt:
            num_cnt[number] = 0
        num_cnt[number] += 1

    # Assert that the first loop correctly computed the frequency of each number.
    # This is the critical bridge lemma needed to prove the postconditions.
    Assert(set(num_cnt.keys()) == set(numbers))
    Assert(all(num_cnt[k] == numbers.count(k) for k in num_cnt.keys()))

    return [number for number in numbers if num_cnt[number] == 1]