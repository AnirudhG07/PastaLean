from collections import defaultdict
from itertools import chain, count


# Nested tuple target with a starred inner element: `(_, *rest)` unpacks the tail of each row.
def heads_and_tails(rows: list[list[int]]) -> int:
    total = 0
    for i, (head, *rest) in enumerate(rows):
        total += head + len(rest)
    return total


# defaultdict with scalar factories: float → 0.0, str → "".
def scalar_defaults(keys: list) -> str:
    sums = defaultdict(float)
    names = defaultdict(str)
    for k in keys:
        sums[k] += 1.5
        names[k] += "x"
    return names[keys[0]] + str(len(sums))


# chain.from_iterable flattens a list of lists.
def flatten_count(xss: list[list[int]]) -> int:
    return len(list(chain.from_iterable(xss)))


# `count()` zipped with a finite list is bounded by it: `zip(xs, count(1))` pairs each with 1,2,3,...
def indexed_sum(xs: list[int]) -> int:
    return sum(v * i for v, i in zip(xs, count(1)))


def main():
    print(heads_and_tails([[10, 1, 2, 3], [20, 4]]))      # (10+3) + (20+1) = 34
    print(scalar_defaults(["a", "a", "b"]))                # "xx" + "2" = "xx2"
    print(flatten_count([[1, 2], [3], [4, 5, 6]]))         # 6
    print(indexed_sum([10, 20, 30]))                       # 10*1 + 20*2 + 30*3 = 140


if __name__ == "__main__":
    main()
