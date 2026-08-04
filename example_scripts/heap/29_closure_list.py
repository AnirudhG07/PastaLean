# A heap-allocated list of closures: `f = []` becomes a `Ref (List (Unit → String))`, and the
# appended lambdas make the element a function type. The empty `allocM []` can't infer the element's
# function-domain universe, so the local must be ascribed from its inferred `list[Callable[[], str]]`.
def functions_append_closure():
    f = []
    for i in range(3):
        f.append(lambda: f"Function {i}")

    for i in range(3):
        f.append(lambda i = i: f"Function {i}")
    for func in f:
        print(func())
