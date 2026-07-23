from contracts import *

def checkOnesSegment(s: str) -> bool:
    Ensures(Result() == ('01' not in s))    # The result is true iff there is no '0'→'1' transition
    return '01' not in s