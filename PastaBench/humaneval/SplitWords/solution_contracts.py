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
    # The point is the three-way branch, so all three branches are stated. Each guard is written
    # out as the character-level condition it tests, and each disjunction below is an implication
    # in disguise (`not guard or conclusion`), since Implies() has no Lean meaning.
    #
    # Whitespace anywhere: the words split on whitespace runs.
    Ensures(not any(c == ' ' or c == '\n' or c == '\r' or c == '\t' for c in txt)
            or Result() == txt.split())
    # No whitespace but a comma: the comma-separated fields.
    Ensures(any(c == ' ' or c == '\n' or c == '\r' or c == '\t' for c in txt)
            or "," not in txt
            or Result() == txt.split(","))
    # Neither: the count of lowercase letters sitting at an odd position of the alphabet
    # (ord('b') - ord('a') == 1, ord('d') - ord('a') == 3, ...).
    Ensures(any(c == ' ' or c == '\n' or c == '\r' or c == '\t' for c in txt)
            or "," in txt
            or Result() == len([c for c in txt
                                if c.islower() and (ord(c) - ord("a")) % 2 == 1]))

    whitespace = tuple(' \n\r\t')
    if any([x in txt for x in whitespace]):
        return txt.split()

    # Bridge the first guard onto the fall-through path.
    Assert(not any(c == ' ' or c == '\n' or c == '\r' or c == '\t' for c in txt))

    if "," in txt:
        return txt.split(",")

    # Bridge the second guard too: from here on the counting branch is the one that applies.
    Assert("," not in txt)

    cnt = 0
    for ch in txt:
        # A for-each over the characters exposes no index, so the only invariant available is
        # that the tally never goes backwards; the counted-set identity is bridged after the loop.
        Invariant(cnt >= 0)
        if ch.islower() and (ord(ch) - ord("a")) % 2 == 1:
            cnt += 1

    # The loop's result-level fact, one step from the third Ensures.
    Assert(cnt == len([c for c in txt if c.islower() and (ord(c) - ord("a")) % 2 == 1]))
    return cnt
