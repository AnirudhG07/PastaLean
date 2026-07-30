# Closure-captured, MUTATED variables under reference semantics (--heap) become shared variable CELLS,
# passed by ref into the capturing sibling — the headline of the cell-sharing model. Two cell shapes:
#   - a mutable CONTAINER capture (`xs.append`) → double ref `Ref (Ref (List Int))`: the rebindable
#     binding (outer ref) and the aliasable object (inner ref). Appends through the closure are seen
#     through `alias`, a second name bound to the SAME object → ([1,2,3,4], [1,2,3,4]).
#   - a mutable SCALAR capture (`nonlocal count`) → single ref `Ref Int`: only the binding is shared,
#     so both `bump` calls accumulate into it → 5 + 3 == 8.
# A cell-promoting function is itself heap-effectful, so its calls are awaited: `counter_closure()` is
# detected via its sibling's `nonlocal` rebind (the driver mirrors the Lean-side promotion) and printed
# below. (A program whose ONLY heap use is a scalar cell has no container/class to emit the `Val`
# universe, so scalar-cell functions stay callable only alongside a container — here, aliased_list_closure.)
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


if __name__ == "__main__":
    aliased_list_closure()
    print(counter_closure())
