def functions_append_closure():
    f = []
    for i in range(3):
        f.append(lambda: f"Function {i}")

    for i in range(3):
        f.append(lambda i = i: f"Function {i}")
    for func in f:
        print(func())