from contracts import *

def check_dict_case(dict):
    """
    Given a dictionary, return True if all keys are strings in lower 
    case or all keys are strings in upper case, else return False.
    The function should return False is the given dictionary is empty.
    Examples:
    check_dict_case({"a":"apple", "b":"banana"}) should return True.
    check_dict_case({"a":"apple", "A":"banana", "B":"banana"}) should return False.
    check_dict_case({"a":"apple", 8:"banana", "a":"apple"}) should return False.
    check_dict_case({"Name":"John", "Age":"36", "City":"Houston"}) should return False.
    check_dict_case({"STATE":"NC", "ZIP":"12345" }) should return True.
    """
    Ensures(Result() == (
        len(dict) > 0 and
        (all(isinstance(k, str) and k.islower() for k in dict.keys()) or
         all(isinstance(k, str) and k.isupper() for k in dict.keys()))
    ))

    keys = list(dict.keys())
    if keys == []: return False
    Assert(len(keys) > 0)

    lower, upper = True, True
    for k in keys:
        # The flags `lower` and `upper` track if all keys *seen so far*
        # could satisfy the all-lowercase or all-uppercase condition.
        Invariant(lower == all(isinstance(p, str) and p.islower() for p in keys[:keys.index(k)]))
        Invariant(upper == all(isinstance(p, str) and p.isupper() for p in keys[:keys.index(k)]))
        if type(k) != str:
            lower = upper = False
            break
        if not k.islower(): lower = False
        if not k.isupper(): upper = False
    
    Assert(lower == all(isinstance(k, str) and k.islower() for k in keys))
    Assert(upper == all(isinstance(k, str) and k.isupper() for k in keys))
    return lower or upper