from contracts import *

def checkString(s: str) -> bool:
    Ensures(Result() == ('ba' not in s))
    return 'ba' not in s