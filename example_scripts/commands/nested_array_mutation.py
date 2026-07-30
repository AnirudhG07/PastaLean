# 2D/3D DP tables built with a comprehension (`[[..] for _ in range(n)]`) and updated in place
# (`f[i][j] = v`). These are Array-backed (O(1) per update via pyModifyItem); correctness must match.
def grid_dp(n: int, m: int) -> int:
    f = [[0] * (m + 1) for _ in range(n + 1)]
    f[0][0] = 1
    for i in range(n + 1):
        for j in range(m + 1):
            if i > 0:
                f[i][j] += f[i - 1][j]
            if j > 0:
                f[i][j] += f[i][j - 1]
    return f[n][m]


def cube_fill(n: int) -> int:
    g = [[[0] * n for _ in range(n)] for _ in range(n)]
    for i in range(n):
        for j in range(n):
            for k in range(n):
                g[i][j][k] = i * 100 + j * 10 + k
    total = 0
    for i in range(n):
        for j in range(n):
            for k in range(n):
                total += g[i][j][k]
    return total


def coin_change(coins: list[int], amount: int) -> int:
    inf = float('inf')
    m, n = len(coins), amount
    f = [[inf] * (n + 1) for _ in range(m + 1)]
    f[0][0] = 0
    for i, x in enumerate(coins, 1):
        for j in range(n + 1):
            f[i][j] = f[i - 1][j]
            if j >= x:
                f[i][j] = min(f[i][j], f[i][j - x] + 1)
    return -1 if f[m][n] >= inf else f[m][n]


def main():
    print(grid_dp(3, 3))                    # C(6,3) = 20 lattice paths
    print(cube_fill(3))                      # sum of i*100+j*10+k over 3x3x3
    print(coin_change([1, 2, 5], 11))        # 3  (5+5+1)
    print(coin_change([2], 3))               # -1


if __name__ == "__main__":
    main()
