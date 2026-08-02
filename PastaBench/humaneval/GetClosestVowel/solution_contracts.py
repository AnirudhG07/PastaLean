from contracts import *


def get_closest_vowel(word):
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
    # THE POINT: The result, if not empty, is a single vowel character from the input word.
    # While we can't easily express the "surrounded by consonants" or "rightmost" properties
    # without quantifiers, we can state these essential properties of the value returned.
    Ensures(Result() == "" or (len(Result()) == 1 and Result() in "aeiouAEIOU" and Result() in word))


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