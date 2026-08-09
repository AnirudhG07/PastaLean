from contracts import *


def get_closest_vowel(word: str):
    """You are given a word. Your task is to find the closest vowel that stands between 
    two consonants from the right side of the word (case sensitive).
    
    Vowels in the beginning and ending doesn't count. Return empty string if you didn't
    find any vowel met the above condition. 

    You may assume that the given string contains English letter only.

    Example:
    get_closest_vowel("yogurt") ==> "u"
    get_closest_vowel("FULL") ==> "U"
    get_closest_vowel("quick") ==> ""
    get_closest_vowel("ab") ==> ""
    """
    # Shape of the answer: either empty or a single vowel taken from the word.
    Ensures(Result() == "" or (len(Result()) == 1 and Result() in "aeiouAEIOU" and Result() in word))
    # THE POINT (a): "" is returned exactly when NO interior position is a vowel flanked by
    # two consonants -- i.e. the search really was exhaustive over 1 .. len(word)-2.
    Ensures(Result() != "" or all(
        not (word[i] in "aeiouAEIOU"
             and word[i - 1] not in "aeiouAEIOU"
             and word[i + 1] not in "aeiouAEIOU")
        for i in range(1, len(word) - 1)))
    # THE POINT (b): a non-empty answer is the RIGHTMOST such position -- it qualifies, and
    # no position strictly to its right qualifies.
    Ensures(Result() == "" or any(
        word[i] == Result()
        and word[i] in "aeiouAEIOU"
        and word[i - 1] not in "aeiouAEIOU"
        and word[i + 1] not in "aeiouAEIOU"
        and all(not (word[j] in "aeiouAEIOU"
                     and word[j - 1] not in "aeiouAEIOU"
                     and word[j + 1] not in "aeiouAEIOU")
                for j in range(i + 1, len(word) - 1))
        for i in range(1, len(word) - 1)))


    def is_vowel(ch: str) -> bool:
        return ch in "aeiouAEIOU"
    for i in range(len(word) - 2, 0, -1):
        # These invariants establish that the indices i, i-1, and i+1 are always valid,
        # which is crucial for proving memory safety of the lookups.
        Invariant(0 < i)
        Invariant(i < len(word) - 1)
        if is_vowel(word[i]) and not is_vowel(word[i-1]) and not is_vowel(word[i+1]):
            return word[i]
    return ""