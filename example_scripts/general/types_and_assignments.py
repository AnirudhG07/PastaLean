from typing import List

inf = float("inf")


def basic_types():
    a = 1
    b = 2.5
    c = "hello"
    d = True
    e = [1, 2]
    f = (1, "a")
    g, h = 3, 4.5
    m, n, p = 5, "world", False
    tup1 = ("foo", 42)
    tup2 = (g, h)

def starred_unpacking(lst: List[int]):
    # `*` collects the middle into a list; elements after the star read from the end, so `last` is
    # always `lst[-1]` regardless of length. `head, *body, last = [1,2,3,4]` → (1, [2,3], 4).
    head, *body, last = lst
    first, *rest = lst
    *init, tail = lst
    return head, body, last, rest, init


def fstring():
    s1 = "Hello"
    s2 = "World"
    s3 = s1 + ", " + s2 + "!"
    return f"This is a string: {s3} and this is a number: {1+2}"

def annotated_vars():
    x: int = 10
    y: int = 20
    return x + y


# Python's numeric tower: int values coerce up to float. These guard the T1 mixed int/float codegen
# coercions the leetcode DP corpus depends on — regressions here are otherwise only caught by rerunning
# the corpus.

def mixed_scalar_accumulator(xs: List[int]) -> float:
    # int-seeded `ans` joins a float (`x / 2`) → must become float; the `0` seed coerces to `(0 : ℚ)`.
    ans = 0
    for x in xs:
        ans = max(ans, x / 2)
    return ans


def int_init_float_container(nums: List[int]) -> List[float]:
    # `dp = [0]*n` later holds floats (`/ 2`) → `List float`, with the `0` element coerced.
    n = len(nums)
    dp = [0] * n
    for i in range(1, n):
        dp[i] = dp[i - 1] / 2 + nums[i]
    return dp


def inf_dp(cost: List[int]) -> int:
    # Canonical `[inf]*n` DP: `inf` adapts to the container's float type across both twins.
    n = len(cost)
    dp = [inf] * (n + 1)
    dp[0] = 0
    for i in range(1, n + 1):
        dp[i] = min(dp[i - 1] + cost[i - 1], dp[i])
    return dp[n]


def grid_inf_dp(houses: List[int]) -> int:
    # A 2-D `[[inf]*k for _ in …]` DP: the comprehension is a nested list-container seeded by the
    # polymorphic `inf`, so it must be ascribed the twin's float type (`List (List ℚ)` / `Float`) —
    # otherwise `inf` defaults to ℚ while the run twin's values are `Float` (a `PySetItem (List ℚ) ℤ
    # Float` clash). Mirrors the allocate-mailboxes shape.
    n = len(houses)
    f = [[inf] * (n + 1) for _ in range(n)]
    for i in range(n):
        f[i][1] = houses[i]
        for j in range(2, i + 2):
            for p in range(i):
                f[i][j] = min(f[i][j], f[p][j - 1] + houses[i])
    return f[n - 1][n]


def heterogeneous_pyany():
    # `[1, "hi", 3]` is `List PyAny`; arithmetic on a boxed element (`* 2`, `+`) dispatches on the tag.
    xs = [1, "hi", 3]
    total = 0
    total = total + xs[0] * 2
    return total


def untyped_param_arithmetic(nums):
    # `nums` is un-inferred → boxed `PyAny`; the two-pass seed propagates `PyAny` to the accumulator so
    # `total` is `PyAny` (not `Int`), matching the boxed element arithmetic.
    total = 0
    for x in nums:
        total += x * 2
    return total


def untyped_param_compare_and_div(nums):
    # Comparison, `%` and `/` on boxed (`PyAny`) values; `best` is a `let mut PyAny` slot reassigned
    # across the loop (not shadowed).
    best = 0
    for x in nums:
        if x > best:
            best = x + x % 3
    return best / 2


def untyped_param_bitwise(nums):
    # Bitwise (`| & `), floor-div (`//`) and shift on boxed (`PyAny`) values.
    r = 0
    for x in nums:
        r = (r | (x & 1)) + x // 2
    return r << 1


def grid_float_dp(m: int, n: int) -> float:
    # 2D grid DP initialised int (`[[0]*n ...]`) that becomes float via `/ 2` — the nested
    # `f[i][j] = ...` teaches `f : list[list[float]]`, coercing the innermost `0`.
    f = [[0] * n for _ in range(m)]
    f[0][0] = 1
    for i in range(m):
        for j in range(n):
            if i > 0:
                f[i][j] += f[i - 1][j] / 2
    return f[m - 1][n - 1]
