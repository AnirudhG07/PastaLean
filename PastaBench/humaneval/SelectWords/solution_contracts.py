from contracts import *

def select_words(s, n):
    """Given a string s and a natural number n, you have been tasked to implement 
    a function that returns a list of all words from string s that contain exactly 
    n consonants, in order these words appear in the string s.
    If the string s is empty then the function should return an empty list.
    Note: you may assume the input string contains only letters and spaces.
    Examples:
    select_words("Mary had a little lamb", 4) ==> ["little"]
    select_words("Mary had a little lamb", 3) ==> ["Mary", "lamb"]
    select_words("simple white space", 2) ==> []
    select_words("Hello world", 4) ==> ["world"]
    select_words("Uncle sam", 3) ==> ["Uncle"]
    """
    Requires(n >= 0)
    # The point of the function: every returned word has exactly n consonants.
    Ensures(all(len([ch for ch in w if ch not in "aeiouAEIOU"]) == n for w in Result()))

    ans = []
    for word in s.split(" "):
        # Accumulator invariant: the property being built up (ans containing only valid words)
        # holds true at the start of every iteration.
        Invariant(all(len([ch for ch in w if ch not in "aeiouAEIOU"]) == n for w in ans))
        if word != "":
            c_cnt = len(list(filter(lambda ch: ch not in "aeiouAEIOU", word)))
            if c_cnt == n: ans.append(word)
    return ans