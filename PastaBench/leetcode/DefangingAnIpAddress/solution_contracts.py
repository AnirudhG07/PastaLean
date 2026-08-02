from contracts import *

def defangIPaddr(address: str) -> str:
    # Direct spec: the result is the address with every '.' replaced by '[.]'. (The previous
    # round-trip form `Result().replace('[.]','.') == address` is false for inputs already
    # containing brackets, e.g. "[.]".)
    Ensures(Result() == address.replace('.', '[.]'))
    return address.replace('.', '[.]')