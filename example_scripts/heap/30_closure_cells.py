# Closure-captured, MUTATED variables under reference semantics (--heap) become shared variable CELLS,
# passed by ref into the capturing sibling — the headline of the cell-sharing model. Two cell shapes:
#   - a mutable CONTAINER capture (`xs.append`) → double ref `Ref (Ref (List Int))`: the rebindable
#     binding (outer ref) and the aliasable object (inner ref). Appends through the closure are seen
#     through `alias`, a second name bound to the SAME object → ([1,2,3,4], [1,2,3,4]).
#   - a mutable SCALAR capture (`nonlocal count`) → single ref `Ref Int`: only the binding is shared,
#     so both `bump` calls accumulate into it → 5 + 3 == 8.
# Both cells are compile-checked here as defs (a scalar-cell function is not yet callable from a
# non-heap context — the driver can't see the Lean-side cell promotion to stamp `_heap_call`).
def aliased_list_closure() -> tuple[list[int], list[int]]:
    xs = [1, 2]
    alias = xs

    def push(v: int) -> int:
        xs.append(v)
        return len(xs)

    push(3)
    push(4)
    return (xs, alias)


def counter_closure() -> int:
    count = 0

    def bump(k: int) -> int:
        nonlocal count
        count += k
        return count

    bump(5)
    bump(3)
    return count
