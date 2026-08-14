# A named nested def passed as `key=` is never called by name, so its param type must be inferred from
# the collection the key ranges over (here `range(n)` → int). Both `min(..., key=f)` and
# `sorted(..., key=f)` exercise it; a `key=lambda` (already handled) is included as a control.
def best_index(vals: list[int]) -> int:
    n = len(vals)

    def score(i: int) -> int:      # `i` is inferred int from `key=score` over range(n)
        return vals[i] * 2 - i

    return min(range(n), key=score)


def sort_by_last_digit(nums: list[int]) -> list[int]:
    def last_digit(x):             # unannotated: type must come from `key=last_digit` over nums
        return x % 10

    return sorted(nums, key=last_digit)


def sort_desc(nums: list[int]) -> list[int]:
    return sorted(nums, key=lambda v: -v)


def main():
    print(best_index([5, 1, 9, 2]))
    print(sort_by_last_digit([23, 41, 15, 8]))
    print(sort_desc([3, 1, 4, 1, 5]))


if __name__ == "__main__":
    main()
