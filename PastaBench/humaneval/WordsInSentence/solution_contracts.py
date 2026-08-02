from typing import *
from contracts import *


def words_in_sentence(sentence: str):
    """
    You are given a string representing a sentence,
    the sentence contains some words separated by a space,
    and you have to return a string that contains the words from the original sentence,
    whose lengths are prime numbers,
    the order of the words in the new string should be the same as the original one.

    Example 1:
        Input: sentence = "This is a test"
        Output: "is"

    Example 2:
        Input: sentence = "lets go for swimming"
        Output: "go for"

    Constraints:
        * 1 <= len(sentence) <= 100
        * sentence contains only letters
    """
    Requires(1 <= len(sentence) <= 100)

    def is_prime(a):
        Requires(a >= 0)
        # The contract for this helper function captures its mathematical intent:
        # determining if a number is prime. A number 'a' is prime if and only if
        # it is greater than 1 and not divisible by any integer from 2 to a-1.
        Ensures(Result() == (a > 1 and all(a % d != 0 for d in range(2, a))))
        return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))
    return " ".join(list(filter(lambda word: is_prime(len(word)), sentence.split(" "))))