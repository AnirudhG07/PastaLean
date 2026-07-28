from typing import Set


def set_method_ops(a: Set[int], b: Set[int]):
    # The pure (non-mutating) set methods return a new set, mirroring the `|`/`&`/`-`/`^` operators.
    u = a.union(b)
    i = a.intersection(b)
    d = a.difference(b)
    s = a.symmetric_difference(b)
    return u, i, d, s


def set_method_predicates(a: Set[int], b: Set[int]):
    # issubset / issuperset / isdisjoint return Bool.
    return a.issubset(b), a.issuperset(b), a.isdisjoint(b)


def set_operator_ops(a: Set[int], b: Set[int]):
    # The operator forms lower to the same runtime functions as the methods above.
    return (a | b), (a & b), (a - b), (a ^ b)
