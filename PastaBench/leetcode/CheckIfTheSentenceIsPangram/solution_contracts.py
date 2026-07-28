from contracts import *

def checkIfPangram(sentence: str) -> bool:
    Ensures(Result() == (len(set(sentence)) == 26))
    return len(set(sentence)) == 26