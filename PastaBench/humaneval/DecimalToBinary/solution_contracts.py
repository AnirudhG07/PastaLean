from contracts import *

def decimal_to_binary(decimal):
    """You will be given a number in decimal form and your task is to convert it to
    binary format. The function should return a string, with each character representing a binary
    number. Each character in the string will be '0' or '1'.

    There will be an extra couple of characters 'db' at the beginning and at the end of the string.
    The extra characters are there to help with the format.

    Examples:
    decimal_to_binary(15)   # returns "db1111db"
    decimal_to_binary(32)   # returns "db100000db"
    """
    Requires(decimal >= 0)
    # The framing, and the fact that something sits between the two markers.
    Ensures(Result().startswith("db"))
    Ensures(Result().endswith("db"))
    Ensures(len(Result()) >= 5)
    # THE POINT (1): the payload between the markers is a genuine binary numeral — every one of
    # its characters is a bit.
    Ensures(all(c == "0" or c == "1" for c in Result()[2:len(Result()) - 2]))
    # THE POINT (2): the payload has exactly the bit-length of `decimal`. Writing k for that
    # length (= len(Result()) - 4), this says 2**(k-1) <= decimal < 2**k, i.e. the numeral is
    # neither padded with leading zeros nor truncated. This is what actually pins the conversion
    # down; it cannot be read off the signature.
    Ensures(decimal < 2 ** (len(Result()) - 4))
    Ensures(decimal == 0 or 2 ** (len(Result()) - 5) <= decimal)

    return "db" + bin(decimal)[2:] + "db"
