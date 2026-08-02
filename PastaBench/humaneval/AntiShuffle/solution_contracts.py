from contracts import *

def anti_shuffle(s: str) -> str:
    """
    Write a function that takes a string and returns an ordered version of it.
    Ordered version of string, is a string where all words (separated by space)
    are replaced by a new word where all the characters arranged in
    ascending order based on ascii value.
    Note: You should keep the order of words and blank spaces in the sentence.

    For example:
    anti_shuffle('Hi') returns 'Hi'
    anti_shuffle('hello') returns 'ehllo'
    anti_shuffle('Hello World!!!') returns 'Hello !!!Wdlor'
    """
    # The number of words (substrings separated by spaces) is preserved.
    Ensures(len(Result().split(" ")) == len(s.split(" ")))
    # Sorting characters within words is a permutation, which preserves the total
    # count of non-space characters across the entire string.
    Ensures(len(Result().replace(" ", "")) == len(s.replace(" ", "")))

    words = s.split(" ")
    return " ".join(map(lambda x: "".join(sorted(x, key=lambda ch: ord(ch))), words))