def builtin_casting():
    a = int("42")
    b = str([1, 2, 3])
    c = list("abc")
    d = str(True)
    e = list((1, 2))
    return a, b, c, d, e

def zero_arg_casts():
    # `int()`/`str()` with no argument are Python's `0` / `""` (e.g. `defaultdict(int)`-style seeds).
    n = int()
    s = str()
    n += 5
    return n, s
