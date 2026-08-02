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
    # The postcondition states that the output is the numerically sorted version of the input words.
    # It handles the empty case, and for non-empty cases, asserts that the output words
    # are in non-decreasing order and that the number of words is preserved.
    # We assume `to_int` is in scope at the function's exit points where the postcondition is checked.
    Ensures(
        (numbers == "" and Result() == "") or
        (numbers != "" and (lambda words:
            len(words) == len(numbers.split(" ")) and
            (len(words) <= 1 or all(
                to_int[words[i]] <= to_int[words[i+1]]
                for i in range(len(words) - 1)
            ))
        )(Result().split(" ")))
    )

    
    to_int = {'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, 'eight': 8, 'nine': 9}

    if numbers == "": return ""
    Assert(numbers != "")
    return " ".join(sorted(numbers.split(" "), key=lambda n: to_int[n]))