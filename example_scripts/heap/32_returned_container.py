# Consuming a heap container RETURNED across a function boundary (--heap). A function whose return
# type is a `list` hands back the object-ref (`Ref (List Int)`), so every consumption of the result
# must dereference it. The driver stamps such calls `_returns_container`; codegen then treats the
# result as a container-ref. Two consumption forms are covered:
#   - BOUND:  `ys = make_squares(4)` registers `ys` as a container, so later `len`/subscript/append/
#     iterate on `ys` dereference the object-ref.
#   - INLINE: `len(make_squares(3))` / `make_squares(3)[2]` / `for x in make_squares(3)` dereference
#     the call result directly (no binding), via the `heapContainerRef?` Call branch.
def make_squares(n: int) -> list[int]:
    out = []
    for i in range(n):
        out.append(i * i)
    return out


if __name__ == "__main__":
    ys = make_squares(4)  # bound object-ref: [0, 1, 4, 9]
    ys.append(99)  # mutate through the bound ref
    print(len(ys))  # 5
    print(ys[0])  # 0
    print(len(make_squares(3)))  # inline len: 3
    print(make_squares(3)[2])  # inline subscript: 4
    running = 0
    for x in make_squares(3):  # inline iterate
        running += x
    print(running)  # 0 + 1 + 4 == 5
