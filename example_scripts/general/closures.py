def functions_append_closure():
    f = []
    for i in range(3):
        f.append(lambda: f"Function {i}")

    for i in range(3):
        f.append(lambda i = i: f"Function {i}")
    for func in f:
        print(func())


def make_adder(n: int):
    # A closure RETURNED as a value: `add` captures `n`. PastaLean lifts `add` to a provable sibling
    # and returns `fun x => add x n` (n baked in) — a genuine Lean closure. `make_adder(5)(3) == 8`.
    def add(x: int) -> int:
        return x + n
    return add


def double(f):
    # A decorator is just a closure returning a wrapper over the decorated function.
    def wrapper(x: int) -> int:
        return 2 * f(x)
    return wrapper


@double
def inc(x: int) -> int:
    return x + 1


def value_capture_loop():
    # The CORRECT loop-closure idiom: `n=n` captures BY VALUE, so each closure keeps its own `n` —
    # which maps naturally to Lean. (Bare `lambda: n` late-binds to the final `n`, a Python footgun.)
    fs = []
    for n in range(3):
        fs.append(lambda n=n: n * n)
    return [g() for g in fs]


def curry_add(a: int):
    # Currying — triple-nested RETURNED closures, each level capturing the one above. Lowers to
    # nested Lean lambdas over lifted `[simp]` siblings. `curry_add(1)(2)(3) == 6`.
    def f(b: int):
        def g(c: int) -> int:
            return a + b + c
        return g
    return f


def add_one(f):
    # A second decorator; stacking `@add_one @double` composes the two wrapper closures.
    def w(x: int) -> int:
        return f(x) + 1
    return w


@add_one
@double
def stacked(x: int) -> int:
    # `stacked(x)` = add_one(double(identity))(x) = 2*x + 1.
    return x


def multi_capture(a: int, b: int, c: int):
    # One closure capturing THREE outer variables at once.
    def poly(x: int) -> int:
        return a * x * x + b * x + c
    return poly


def sibling_closures(a: int, b: int):
    # `apply3` (a 0-arg closure) CALLS the sibling closure `lin`, and is RETURNED. Calling the returned
    # 0-arg closure applies it to `Unit`: `sibling_closures(2, 1)() == lin(3) == 2*3 + 1 == 7`.
    def lin(x: int) -> int:
        return a * x + b
    def apply3() -> int:
        return lin(3)
    return apply3


def closure_theorems():
    # Properties of the closures above, PROVED automatically on conversion (`--prove-asserts`): each
    # `assert` becomes a Lean theorem `:= by taste?` and the proof search splices the winning tactic.
    assert make_adder(5)(3) == 8
    assert curry_add(1)(2)(3) == 6
    assert make_adder(2)(make_adder(3)(10)) == 15      # adders compose: (10+3)+2
    assert multi_capture(1, 2, 3)(4) == 27             # 1*16 + 2*4 + 3
    assert sibling_closures(2, 1)() == 7               # returned 0-arg closure calling a sibling