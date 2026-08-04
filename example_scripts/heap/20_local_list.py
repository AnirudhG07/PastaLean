# A bare local list (no class): built, aliased, mutated through the alias, iterated, and indexed.
# `ys = xs` shares the same heap list, so `ys.append` is visible via `xs`. Returns 7.
def demo():
    xs = [1]
    xs.append(2)
    ys = xs           # alias: same heap list
    ys.append(3)      # xs is now [1, 2, 3]
    total = 0
    for v in xs:
        total = total + v
    return total + xs[0]   # (1+2+3) + 1
