from contracts import *

def minimizedStringLength(s: str) -> int:
    Ensures(Result() == len(set(s)))
    return len(set(s))