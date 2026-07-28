from contracts import *

def isAcronym(words: List[str], s: str) -> bool:
    Requires(all(len(w) > 0 for w in words))
    return ''.join((w[0] for w in words)) == s