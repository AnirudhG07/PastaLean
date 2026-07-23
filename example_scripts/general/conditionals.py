def check_nesting(n, m):
    if n > 0:
        if m >= 0:
            return "Both positive"
        else:
            return "n positive, m non-positive"
    else:
        if m > 0:
            return "n non-positive, m positive"
        else:
            return "Both non-positive"

def super_nested_if(a: bool, b: bool, c: bool, d: bool):
    if a:
        if b:
            if c:
                if d:
                    return 1
                else:
                    return 2
            else:
                return 3
        else:
            return 4
    else:
        return 5

def complex_branching(x):
    if x == 1:
        return "one"
    elif x == 2:
        return "two"
    elif x == 3:
        return "three"
    else:
        return "other"

def cond_multi(x:int):
    a, b, c = 1,2,1
    if (a<b>c):
        x += 1


def cond_none(x):
    s = ""
    if x is None:
        s = "x is None"
    y = 10
    if y is not None:
        s += "y is not None"

    if (None is None) and (None == None):
        s += "None is None"
    if (None is not None) or (None != None):
        s += "None is not None"
    return s


def value_or_default(xs: list):
    # `a or b` in a VALUE position returns the deciding operand, not a Bool: `xs or [0]` is the list.
    return max(xs or [0])
