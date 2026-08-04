# Consuming a RETURNED tuple-of-containers, unpacked at module scope (--heap). A function returning
# `tuple[list, list]` hands back a pair of object-refs; the main-guard unpack `xs, ys = split(...)`
# must register BOTH targets as container-refs (`_unpack_container_mask`, stamped only once the guard
# body is inferred with the full interprocedural `sigs`) so every downstream use dereferences.
# Exercises three consumption families the earlier heap examples did not:
#   - print(container-ref) and print((xs, ys)) — a print / tuple-literal derefs each container element.
#   - builtins consuming an iterable BY VALUE — sum/min/max/sorted deref the ref to its contents.
#   - subscript / len on the unpacked refs.
def split_parity(n: int) -> tuple[list[int], list[int]]:
    evens = []
    odds = []
    for i in range(n):
        if i % 2 == 0:
            evens.append(i)
        else:
            odds.append(i)
    return (evens, odds)


if __name__ == "__main__":
    xs, ys = split_parity(6)          # xs=[0, 2, 4], ys=[1, 3, 5]
    print(xs)                         # [0, 2, 4]
    print((xs, ys))                   # ([0, 2, 4], [1, 3, 5])
    print(len(xs))                    # 3
    print(xs[2])                      # 4
    print(sum(xs))                    # 6
    print(min(ys))                    # 1
    print(max(ys))                    # 5
    print(sorted(xs, reverse=True))   # [4, 2, 0]
