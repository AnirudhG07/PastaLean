from contracts import *

def histogram(test):
    """Given a string representing a space separated lowercase letters, return a dictionary
    of the letter with the most repetition and containing the corresponding count.
    If several letters have the same occurrence, return all of them.

    Example:
    histogram('a b c') == {'a': 1, 'b': 1, 'c': 1}
    histogram('a b b a') == {'a': 2, 'b': 2}
    histogram('a b c a b') == {'a': 2, 'b': 2}
    histogram('b b b b a') == {'b': 4}
    histogram('') == {}

    """
    # Precondition: The input string must either be empty, or contain at least
    # one non-whitespace character. This prevents a ValueError on max() of an
    # empty list for inputs like " " or "   ".
    Requires(test == "" or test.strip() != "")

    # Postcondition: an empty input string yields an empty histogram (the
    # `histogram('') == {}` boundary case). This is the tractable characterization
    # proved in Proofs.lean (`histogram_empty`); the `forall`/`exists` quantifier
    # form used previously is not supported by the transpiler.
    Ensures((test != "") or (Result() == {}))

    if test == "": return {}

    count, ans = dict(), dict()
    for word in test.split(" "):
        if word != "":
            if word not in count: count[word] = 0
            count[word] += 1

    mx = max(list(count.values()))

    for ch, c in count.items():
        if c == mx:
            ans[ch] = c

    return ans
