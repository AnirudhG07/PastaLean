# SSA renaming on TYPE MUTATIONS: `digits` holds a list[str] before the branch and a list[int] after,
# reassigned to a different element type inside both branches. SSA versions it (`digits`, `digits'vN`)
# so each is typed CONCRETELY (List String / List Int) instead of boxed to PyAny, and the branch join
# is a hoisted phi. Both branches agree on the new type, so the merge stays concrete.
def digit_parity(x: int) -> int:
    digits = list(str(x))          # list[str]
    if digits[0] == "-":
        digits = list(map(int, digits[1:]))   # list[int]
    else:
        digits = list(map(int, digits))        # list[int]
    return sum(d for d in digits if d % 2 == 0)


def main():
    print(digit_parity(2468))      # 2+4+6+8 = 20
    print(digit_parity(13579))     # 0 (no even digits)


if __name__ == "__main__":
    main()
