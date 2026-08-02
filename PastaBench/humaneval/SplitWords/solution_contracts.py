from contracts import *

def split_words(txt):
    '''
    Given a string of words, return a list of words split on whitespace, if no whitespaces exists in the text you
    should split on commas ',' if no commas exists you should return the number of lower-case letters with odd order in the
    alphabet, ord('a') = 0, ord('b') = 1, ... ord('z') = 25
    Examples
    split_words("Hello world!") ➞ ["Hello", "world!"]
    split_words("Hello,world!") ➞ ["Hello", "world!"]
    split_words("abcdef") == 3 
    '''
    Ensures(
        Implies(any(c in txt for c in ' \n\r\t'),
                Result() == txt.split())
    )
    Ensures(
        Implies(not any(c in txt for c in ' \n\r\t') and "," in txt,
                Result() == txt.split(","))
    )
    Ensures(
        Implies(not any(c in txt for c in ' \n\r\t') and "," not in txt,
                Result() == sum(1 for ch in txt if ch.islower() and (ord(ch) - ord("a")) % 2 == 1))
    )

    whitespace = tuple(' \n\r\t')
    if any([x in txt for x in whitespace]):
        return txt.split()

    Assert(not any(c in txt for c in ' \n\r\t'))

    if "," in txt:
        return txt.split(",")

    Assert(not any(c in txt for c in ' \n\r\t') and "," not in txt)

    cnt = 0
    for ch in txt:
        # This invariant is too weak to prove the final sum, as a for-each loop
        # does not expose an index to relate the accumulator to the prefix of `txt`.
        Invariant(cnt >= 0)
        if ch.islower() and (ord(ch) - ord("a")) % 2 == 1:
            cnt += 1
    
    # This assertion bridges the loop's result to the Ensures clause.
    # Proving it would require a stronger loop invariant.
    Assert(cnt == sum(1 for c in txt if ch.islower() and (ord(ch) - ord("a")) % 2 == 1))
    return cnt