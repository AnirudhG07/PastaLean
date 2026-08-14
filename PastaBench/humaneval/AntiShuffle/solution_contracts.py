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
    # Splitting on " " and re-joining on " " is length-preserving on the whole string,
    # and preserves the word decomposition position for position.
    Ensures(len(Result()) == len(s))
    Ensures(len(Result().split(" ")) == len(s.split(" ")))
    # THE POINT (a): every output word is in ascending ASCII order.
    Ensures(all("".join(sorted(w)) == w for w in Result().split(" ")))
    # THE POINT (b): each output word is a permutation of the input word at the same
    # position -- together with (a) this pins the result exactly.
    Ensures(all(sorted(Result().split(" ")[i]) == sorted(s.split(" ")[i])
                for i in range(len(s.split(" ")))))

    words = s.split(" ")
    return " ".join(map(lambda x: "".join(sorted(x, key=lambda ch: ord(ch))), words))