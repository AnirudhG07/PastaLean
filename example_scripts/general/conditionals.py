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


def hoist_conflicting_branches(c: int) -> str:
    # A name Python assigns at DIFFERENT types across branches leaks out of the `if` (Python has no
    # block scope; Lean does). It is hoisted to `let mut v : PyAny := emptyPyAny` before the `if`, and
    # each branch REASSIGNS (boxing): `v = 5` / `v = "hi"` all mutate one PyAny variable.
    if c > 0:
        v = 5
    else:
        v = "hi"
    return str(v)


def hoist_partial_branch(c: int) -> int:
    # `total` is first bound inside a branch and read after the `if`; hoisted with its inferred type
    # (`let mut total : Int := default`) so the post-`if` read sees a single variable.
    if c > 0:
        total = c * 2
    else:
        total = -1
    return total
