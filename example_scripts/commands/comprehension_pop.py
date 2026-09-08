# A value-and-mutate call (`pop`) as a comprehension element: it mutates per iteration, so it can't be
# hoisted out — the comprehension is unfolded to an explicit `acc = []; for …: acc.append(x.pop())`
# loop, and the `pop` is then split inside the loop body.
def drain_last(buckets: dict) -> list[int]:
    return [buckets[k].pop() for k in [1, 2, 1]]


# An `if` clause inside the comprehension must guard the (mutating) append.
def drain_if(buckets: dict, ks: list[int]) -> list[int]:
    return [buckets[k].pop() for k in ks if buckets[k]]


def join_pops(groups: dict) -> str:
    return "".join((groups[i].pop() for i in range(3)))


def main():
    b = {1: [10, 11], 2: [20]}
    print(drain_last(b))            # pop 11, 20, 10  -> [11, 20, 10]
    print(drain_if({1: [7], 2: []}, [1, 2, 1]))   # k=1 ok->7, k=2 empty->skip, k=1 empty->skip -> [7]
    g = {0: ["a", "b"], 1: ["c"], 2: ["d", "e"]}
    print(join_pops(g))             # "b" + "c" + "e" -> "bce"


if __name__ == "__main__":
    main()
