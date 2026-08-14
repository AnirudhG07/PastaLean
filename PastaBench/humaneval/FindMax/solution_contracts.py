from contracts import *


def find_max(words):
    """Write a function that accepts a list of strings.
    The list contains different words. Return the word with maximum number
    of unique characters. If multiple strings have maximum number of unique
    characters, return the one which comes first in lexicographical order.

    find_max(["name", "of", "string"]) == "string"
    find_max(["name", "enam", "game"]) == "enam"
    find_max(["aaaaaaa", "bb" ,"cc"]) == ""aaaaaaa"
    """
    # Ensures that the function returns one of the original words, or the empty
    # string if the input list was empty. This is a key property about the
    # function's output domain.
    Ensures(len(words) == 0 and Result() == "" or Result() in words)

    mx_ch_cnt, ans = 0, ""
    for word in words:
        # Invariant: The running count of unique characters is non-negative.
        Invariant(mx_ch_cnt >= 0)
        # Invariant: The running count is always consistent with the number of unique
        # characters in the current best-candidate answer. This is the central
        # property that ties the two loop-carried state variables together.
        Invariant(mx_ch_cnt == len(set(ans)))
        # Invariant: The candidate answer is always either the initial empty string
        # or a word that has been seen in the input list. This is crucial for
        # proving the postcondition.
        Invariant(ans == "" or ans in words)

        ch_cnt = len(set(word))
        if ch_cnt > mx_ch_cnt or (ch_cnt == mx_ch_cnt and word < ans):
            mx_ch_cnt, ans = ch_cnt, word

    # After the loop, the invariant about the answer's origin still holds,
    # which directly implies the postcondition.
    Assert(ans == "" or ans in words)
    return ans