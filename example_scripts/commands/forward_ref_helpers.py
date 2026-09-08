def count_beautiful_pairs(nums: list[int]) -> int:
    n = len(nums)
    ans = 0
    for i in range(n):
        for j in range(i):
            ans += chk(nums[j], nums[i])
    return ans


def chk(n1: int, n2: int) -> int:
    return 1 if gcd(n1, n2) == 1 else 0


def gcd(x: int, y: int) -> int:
    if y == 0:
        return x
    return gcd(y, x % y)


def is_even(n: int) -> bool:
    if n == 0:
        return True
    return is_odd(n - 1)


def is_odd(n: int) -> bool:
    if n == 0:
        return False
    return is_even(n - 1)


def main():
    print(count_beautiful_pairs([2, 3, 4, 5]))
    print(is_even(10))


if __name__ == "__main__":
    main()
