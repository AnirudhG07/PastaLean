from collections import defaultdict


def count_interesting(nums: list[int], m: int, k: int) -> int:
    n = len(nums)
    a = [0 for _ in range(n + 1)]

    def zero():
        return 0

    for i in range(n):
        if nums[i] % m == k:
            a[i + 1] = 1
    for i in range(1, n + 1):
        a[i] += a[i - 1]
    cnt = defaultdict(zero)
    ans = 0
    for i in range(n + 1):
        ans += cnt[(a[i] - k + m) % m]
        cnt[a[i] % m] += 1
    return ans


def main():
    print(count_interesting([3, 1, 9, 6], 3, 0))


if __name__ == "__main__":
    main()
