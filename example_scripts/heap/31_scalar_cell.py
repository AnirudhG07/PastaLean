# A closure whose ONLY heap use is a scalar CELL (`nonlocal`): no containers, no classes anywhere.
# The captured, rebound scalar becomes a single `Ref Int`, which forces the `Val` universe to exist
# even though nothing else touches the heap — the boundary the scalar-cell prelude fixes. Without it,
# `HeapM Val` has an undefined `Val`. Both call forms are awaited (nested `print`, and an assignment),
# each accumulating 1 + 2 == 3.
def running_total() -> int:
    total = 0

    def add(k: int) -> int:
        nonlocal total
        total += k
        return total

    add(1)
    add(2)
    return total


if __name__ == "__main__":
    print(running_total())
    result = running_total()
    print(result)
