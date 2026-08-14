from typing import List
from contracts import *


def sort_numbers(numbers: str) -> str:
    """ Input is a space-delimited string of numberals from 'zero' to 'nine'.
    Valid choices are 'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight' and 'nine'.
    Return the string with numbers sorted from smallest to largest
    >>> sort_numbers('three one five')
    'one three five'
    """
    Requires(
        numbers == "" or all(
            word in ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']
            for word in numbers.split(" ")
        )
    )
    # 1. The output words are a permutation of the input words (a rearrangement, nothing added
    #    or dropped) — same count, same multiset.
    Ensures(len(Result().split(" ")) == len(numbers.split(" ")))
    Ensures(sorted(Result().split(" ")) == sorted(numbers.split(" ")))
    # 2. The output words are in non-decreasing NUMERIC order. The numeral's value is its position
    #    in the vocabulary list, spelled out inline so the contract needs no function-local name.
    Ensures(all(
        ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']
            .index(Result().split(" ")[j])
        <= ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine']
            .index(Result().split(" ")[j + 1])
        for j in range(len(Result().split(" ")) - 1)))


    to_int = {'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9}

    if numbers == "": return ""
    Assert(numbers != "")
    return " ".join(sorted(numbers.split(" "), key=lambda n: to_int[n]))