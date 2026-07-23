from contracts import *

def defangIPaddr(address: str) -> str:
    Ensures(Result().replace('[.]', '.') == address)
    return address.replace('.', '[.]')