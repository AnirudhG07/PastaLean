from collections import Counter, defaultdict


def beautiful(s: str, k: int) -> int:
    cc = [Counter() for _ in range(k)]
    cc[0][0] = 1
    ans = cur = 0
    for i, x in enumerate(s, 1):
        cur += 1 if x in 'aeiou' else -1
        ans += cc[i % k][cur]
        cc[i % k][cur] += 1
    return ans


def arithmetic(nums: list[int]) -> int:
    f = [defaultdict(int) for _ in nums]
    ans = 0
    for i, x in enumerate(nums):
        for j in range(i):
            d = x - nums[j]
            ans += f[j][d]
            f[i][d] += f[j][d] + 1
    return ans


def main():
    print(beautiful("baeyh", 2))
    print(arithmetic([2, 4, 6, 8, 10]))


if __name__ == "__main__":
    main()
