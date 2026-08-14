from contracts import *

def is_bored(S: str) -> int:
    """
    You'll be given a string of words, and your task is to count the number
    of boredoms. A boredom is a sentence that starts with the word "I".
    Sentences are delimited by '.', '?' or '!'.
   
    For example:
    >>> is_bored("Hello world")
    0
    >>> is_bored("The sky is blue. The sun is shining. I love this weather")
    1
    """
    Ensures(Result() >= 0)
    # The number of "boredoms" cannot exceed the total number of sentences.
    Ensures(Result() <= len(((S.replace("?", ".")).replace("!", ".")).split(".")))

    sentences = map(lambda x: x.strip(), ((S.replace("?", ".")).replace("!", ".")).split("."))
    return len([s for s in sentences if s.startswith("I ")])