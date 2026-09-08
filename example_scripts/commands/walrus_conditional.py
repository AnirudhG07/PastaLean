# Walrus in an `and`-test, evaluated conditionally: the walrus target must NOT be computed when the
# left operand is false (here `d[t]` would KeyError). The desugarer unfolds the short-circuit into
# nested ifs / break-guards so `k`/`m` run at their real position and still reach the body.
def scan(d: dict, xs: list) -> int:
    total = 0
    for t in xs:
        if t in d and (k := d[t]) < 100:
            total += k
    return total


def window(s: list, limit: int) -> int:
    i, best = 0, 0
    while i < len(s) and (m := s[i] * 2) <= limit:
        best = max(best, m)
        i += 1
    return best


def main():
    print(scan({1: 10, 2: 50, 3: 200}, [1, 2, 3, 4]))
    print(window([1, 2, 3, 40], 10))


if __name__ == "__main__":
    main()
