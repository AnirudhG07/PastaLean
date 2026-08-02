from contracts import *


def Strongest_Extension(class_name, extensions):
    """You will be given the name of a class (a string) and a list of extensions.
    The extensions are to be used to load additional classes to the class. The
    strength of the extension is as follows: Let CAP be the number of the uppercase
    letters in the extension's name, and let SM be the number of lowercase letters 
    in the extension's name, the strength is given by the fraction CAP - SM. 
    You should find the strongest extension and return a string in this 
    format: ClassName.StrongestExtensionName.
    If there are two or more extensions with the same strength, you should
    choose the one that comes first in the list.
    For example, if you are given "Slices" as the class and a list of the
    extensions: ['SErviNGSliCes', 'Cheese', 'StuFfed'] then you should
    return 'Slices.SErviNGSliCes' since 'SErviNGSliCes' is the strongest extension 
    (its strength is -1).
    Example:
    for Strongest_Extension('my_class', ['AA', 'Be', 'CC']) == 'my_class.AA'
    """
    Requires(len(extensions) > 0)

    # The point of the function is that the extension part of the result string
    # is a member of the input list and has a strength equal to the maximum
    # strength found in that list. The tie-breaking rule (first wins) is
    # ensured by the sequential search logic of the `for` loop.
    Ensures(Result().split('.')[-1] in extensions)
    Ensures(strength(Result().split('.')[-1]) == max(map(strength, extensions)))

    def strength(s: str) -> int:
        CAP, SM = 0, 0
        for ch in s:
            Invariant(CAP >= 0)
            Invariant(SM >= 0)
            if ch.isupper(): CAP += 1
            if ch.islower(): SM += 1
        return CAP - SM

    max_strength = max(map(strength, extensions))
    for e in extensions:
        if strength(e) == max_strength:
            # Bridge assertion: By finding an `e` where `strength(e) == max_strength`,
            # we have found an element whose strength is equal to the overall maximum.
            # This fact is needed to prove the postcondition.
            Assert(strength(e) == max(map(strength, extensions)))
            return class_name + "." + e