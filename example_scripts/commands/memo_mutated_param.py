# A @cache-memoized recursive DP whose body REASSIGNS a parameter (`k += ...`). The memoized run-twin
# binds params as immutable binders, so each mutated param needs a `let mut k := k` shadow — without it
# the reassignment fails to elaborate ("`k` cannot be mutated").
from functools import cache


def ways(corridor: str) -> int:
    n = len(corridor)

    @cache
    def dfs(i: int, k: int) -> int:
        if i >= n:
            return int(k == 2)
        k += int(corridor[i] == 'S')
        if k > 2:
            return 0
        ans = dfs(i + 1, k)
        if k == 2:
            ans += dfs(i + 1, 0)
        return ans

    return dfs(0, 0)


def main():
    print(ways("SSPPSPS"))
    print(ways("PPSPSP"))


if __name__ == "__main__":
    main()
