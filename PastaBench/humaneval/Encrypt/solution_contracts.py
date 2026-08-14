from contracts import *


def encrypt(s: str) -> str:
    """Create a function encrypt that takes a string as an argument and
    returns a string encrypted with the alphabet being rotated. 
    The alphabet should be rotated in a manner such that the letters 
    shift down by two multiplied to two places.
    For example:
    encrypt('hi') returns 'lm'
    encrypt('asdfghjkl') returns 'ewhjklnop'
    encrypt('gf') returns 'kj'
    encrypt('et') returns 'ix'
    """
    # The map is char-for-char, so the length is preserved.
    Ensures(len(Result()) == len(s))
    # THE POINT: on the lowercase alphabet this is the rotation by 2*2 = 4, stated
    # modularly (so the wrap-around from 'w'..'z' is covered by the same clause) and
    # closed on 'a'..'z'; every other character is left alone.
    Ensures(all("a" <= Result()[i] <= "z" for i in range(len(s)) if "a" <= s[i] <= "z"))
    Ensures(all(Result()[i] == "abcdefghijklmnopqrstuvwxyz"[(ord(s[i]) - ord("a") + 4) % 26]
                for i in range(len(s)) if "a" <= s[i] <= "z"))
    Ensures(all(Result()[i] == s[i]
                for i in range(len(s)) if not ("a" <= s[i] <= "z")))
    d = 'abcdefghijklmnopqrstuvwxyz'
    return "".join(map(lambda ch: chr((ord(ch) - ord("a") + 4) % 26 + ord("a")) if ch in d else ch, s))