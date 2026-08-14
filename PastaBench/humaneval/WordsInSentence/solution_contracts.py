from typing import *
from contracts import *


def is_prime(a):
    Requires(a >= 0)
    # Primality in full: a > 1 and no candidate divisor in range(2, a) divides it. Stating it
    # over the whole range rather than up to sqrt(a) is what makes this a real obligation.
    Ensures(Result() == (a > 1 and all(a % d != 0 for d in range(2, a))))
    return not (a < 2 or any(a % x == 0 for x in range(2, int(a ** 0.5) + 1)))


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
    Requires(len(sentence) >= 1)
    Requires(len(sentence) <= 100)
    # The point: exactly the words whose length is prime, in their original order — primality
    # spelled out as trial division over range(2, n), not delegated to the sqrt-bounded helper.
    Ensures(Result() == " ".join([w for w in sentence.split(" ")
                                  if len(w) > 1 and all(len(w) % d != 0
                                                        for d in range(2, len(w)))]))
    # Consequences worth naming: every word that comes out has prime length, and comes from the
    # input (nothing is invented or reshaped).
    Ensures(all(len(w) > 1 and all(len(w) % d != 0 for d in range(2, len(w)))
                for w in Result().split(" ") if w != ""))
    Ensures(all(w in sentence.split(" ") for w in Result().split(" ") if w != ""))

    return " ".join(list(filter(lambda word: is_prime(len(word)), sentence.split(" "))))
