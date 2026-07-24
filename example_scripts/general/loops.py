def nested_loops(n):
    total = 0
    for i in range(n):
        for j in range(i):
            total += j
    return total

def super_nested_loops(n):
    res = 0
    for i in range(n):
        for j in range(n):
            for k in range(n):
                for l in range(n):
                    res += i + j + k + l
    return res

def while_in_for(n):
    count = 0
    for i in range(n):
        j = i
        while j > 0:
            count += 1
            j -= 1
    return count

def breakable_loop(n):
    total = 0
    for i in range(n):
        if i == 5:
            break
        total += i
    j = 0
    while j < n:
        if j <= 3:
            continue
        total += j
        j += 1

    return total


def for_leaks_out(n: int) -> int:
    # A name first bound inside a loop leaks OUT of it (Python is function-scoped; Lean's loop body is
    # its own scope). `x` is read after the loop, so it is hoisted to `let mut x : Int := default`
    # before the loop and the body reassigns it.
    for i in range(n):
        x = i * 2
    return x


def nested_leaks_out(n: int) -> int:
    # `y` is first bound in the INNERMOST loop yet read after the OUTERMOST — it hoists all the way to
    # the function scope (the annotate pass collects an inner-bound name at the outer loop).
    for i in range(n):
        for j in range(n):
            y = i * j
    return y


def loop_leak_conflicting(n: int) -> str:
    # A loop-body name bound at DIFFERENT types across branches leaks out as `PyAny` (hoisted before
    # the loop as `let mut z : PyAny := emptyPyAny`; each branch reassigns, boxing).
    for i in range(n):
        if i % 2 == 0:
            z = i
        else:
            z = "odd"
    return str(z)