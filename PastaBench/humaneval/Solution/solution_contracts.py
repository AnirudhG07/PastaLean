from contracts import *
from typing import List


def solution(lst: List[int]) -> int:
    """Given a non-empty list of integers, return the sum of all of the odd elements that are in even positions.


    Examples
    solution([5, 8, 7, 1]) ==> 12
    solution([3, 3, 3, 3, 3]) ==> 9
    solution([30, 13, 24, 321]) ==>0
    """
    Requires(len(lst) > 0)  # As per the docstring "non-empty list"

    # The point: the accumulator loop below computes exactly the fold over the even
    # positions holding an odd value.
    Ensures(Result() == sum(lst[i] for i in range(len(lst)) if i % 2 == 0 and lst[i] % 2 == 1))
    # A sum of k odd terms is congruent to k mod 2 — a fact about the summands, not the fold.
    Ensures(
        Result() % 2
        == len([i for i in range(len(lst)) if i % 2 == 0 and lst[i] % 2 == 1]) % 2
    )

    total = 0
    for i in range(len(lst)):
        # The loop counter `i` is bounded by the length of the list.
        Invariant(0 <= i)
        Invariant(i <= len(lst))
        # Index-style: the running total is the fold over the prefix already scanned, so at
        # exit it literally is the Ensures.
        Invariant(total == sum(lst[j] for j in range(i) if j % 2 == 0 and lst[j] % 2 == 1))
        Invariant(
            total % 2
            == len([j for j in range(i) if j % 2 == 0 and lst[j] % 2 == 1]) % 2
        )

        if i % 2 == 0 and lst[i] % 2 == 1:
            total = total + lst[i]

    Assert(total == sum(lst[i] for i in range(len(lst)) if i % 2 == 0 and lst[i] % 2 == 1))
    return total
