# A user function named `max` shadows Python's builtin AND Lean's `Max.max`; every call must resolve
# to the user's def (renamed internally so it isn't ambiguous). `str.startswith`/`endswith` with a
# start (and end) index restrict the check to a slice.
def max(a: int, b: int) -> int:
    if a > b:
        return a
    return b


def best(xs: list[int]) -> int:
    ans = xs[0]
    for x in xs:
        ans = max(ans, x)
    return ans


def count_prefixes(s: str, p: str) -> int:
    total = 0
    for i in range(len(s)):
        if s.startswith(p, i):
            total += 1
    return total


def main():
    print(best([3, 7, 2, 9, 4]))
    print(count_prefixes("ababab", "ab"))
    print("hello world".endswith("lo", 0, 5))


if __name__ == "__main__":
    main()
