from collections import defaultdict


def count_pairs(coordinates: list[list[int]], k: int) -> int:
    mp = defaultdict(int)
    for x, y in coordinates:
        mp[(x, y)] += 1
    res = 0
    for i in range(k + 1):
        a, b = i, k - i
        tmp = mp.copy()
        for x, y in coordinates:
            tmp[(x, y)] -= 1
            if (a ^ x, b ^ y) in tmp:
                res += tmp[(a ^ x, b ^ y)]
    return res


def main():
    print(count_pairs([[1, 2], [4, 5], [1, 2]], 5))


if __name__ == "__main__":
    main()
