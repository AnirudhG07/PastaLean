from contracts import *

def doesAliceWin(s: str) -> bool:
    Ensures(Result() == any(c in 'aeiou' for c in s))
    vowels = set('aeiou')
    return any((c in vowels for c in s))