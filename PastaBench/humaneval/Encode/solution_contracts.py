from contracts import *


def encode(message: str) -> str:
    """
    Write a function that takes a message, and encodes in such a 
    way that it swaps case of all letters, replaces all vowels in 
    the message with the letter that appears 2 places ahead of that 
    vowel in the english alphabet. 
    Assume only letters. 
    
    Examples:
    >>> encode('test')
    'TGST'
    >>> encode('This is a message')
    'tHKS KS C MGSSCGG'
    """
    # Both passes are char-for-char, so the length is preserved.
    Ensures(len(Result()) == len(message))
    # THE POINT (a): character-set closure. Every vowel of the case-swapped message is
    # shifted to a+2 = c, e+2 = g, i+2 = k, o+2 = q, u+2 = w (same for uppercase), none of
    # which is a vowel, and no non-vowel is touched -- so the output has no vowels at all.
    Ensures(all(c not in "aeiouAEIOU" for c in Result()))
    # THE POINT (b): case really is swapped -- the +2 vowel shift never crosses a case
    # boundary, so an alphabetic input character comes out in the opposite case.
    Ensures(all(Result()[i].islower() == message[i].isupper()
                for i in range(len(message)) if message[i].isalpha()))


    def switch_case(ch: str) -> str:
        Requires(len(ch) == 1)
        if ord("A") <= ord(ch) <= ord("Z"):
            return chr(ord(ch) + 32)
        elif ord("a") <= ord(ch) <= ord("z"):
            return chr(ord(ch) - 32)
        else:
            return ch
    
    def vowel_change(ch: str) -> str:
        Requires(len(ch) == 1)
        return ch if ch not in "aeiouAEIOU" else chr(ord(ch) + 2)
    
    m = "".join(map(switch_case, message))
    Assert(len(m) == len(message))
    return "".join(map(vowel_change, m))