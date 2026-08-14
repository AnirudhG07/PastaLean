# Regression tests for nested-def state threading (ClosureConvert).
# Each function exercises a pattern that was a convert/compile failure before the
# SCC-grouping + cross-helper + mutable-param + comprehension-hoist work.

from typing import List
from heapq import *


# Union-find: `find` (self-recursive, mutates captured `p` via path compression) plus a
# sibling `union` that CALLS `find`. `union -> find` is a DAG, so they lift as separate
# threaded helpers and `union`'s `find` calls thread `p` across the boundary.
def count_components(n: int, edges: List[List[int]]) -> int:
    p = list(range(n))

    def find(x: int) -> int:
        if p[x] != x:
            p[x] = find(p[x])
        return p[x]

    def union(a: int, b: int) -> None:
        pa, pb = (find(a), find(b))
        if pa != pb:
            p[pa] = pb

    for a, b in edges:
        union(a, b)
    return len(set(find(i) for i in range(n)))


# `while find(a) != find(b):` — a threaded call in a `while` TEST (re-evaluated each
# iteration). Lowers to `while True: <thread test>; if not test: break; <body>`.
def connect_until_joined(n: int, edges: List[List[int]]) -> int:
    p = list(range(n))

    def find(x: int) -> int:
        if p[x] != x:
            p[x] = find(p[x])
        return p[x]

    steps = 0
    i = 0
    while find(0) != find(n - 1) and i < len(edges):
        a, b = edges[i]
        p[find(a)] = find(b)
        steps += 1
        i += 1
    return steps


# Mutable PARAMETER threading: `push` mutates its `pq` argument in place (heappush /
# heappop) and its caller must see the change — the arg is rebound at the call site.
def k_smallest_after_pushes(nums: List[int], k: int) -> List[int]:
    def push(pq: List[int], x: int) -> None:
        heappush(pq, -x)
        if len(pq) > k:
            heappop(pq)

    heap: List[int] = []
    for v in nums:
        push(heap, v)
    return sorted(-x for x in heap)


# A mutated parameter via a tuple-of-subscripts target (`arr[i], arr[j] = arr[j], arr[i]`).
def selection_sort(arr: List[int]) -> List[int]:
    def swap(a: List[int], i: int, j: int) -> None:
        a[i], a[j] = (a[j], a[i])

    for i in range(len(arr)):
        m = i
        for j in range(i + 1, len(arr)):
            if arr[j] < arr[m]:
                m = j
        swap(arr, i, m)
    return arr


# Short-circuited threaded call in an accumulator comprehension: `dfs` (mutating captured
# `color`) runs only when `color[i] == 0` — the `or` is lowered to an `if` per item so the
# mutation stays behind the short-circuit.
def is_bipartite(n: int, graph: List[List[int]]) -> bool:
    color = [0] * n

    def dfs(i: int, c: int) -> bool:
        color[i] = c
        for j in graph[i]:
            if color[j] == c:
                return False
            if color[j] == 0 and (not dfs(j, -c)):
                return False
        return True

    return all(color[i] != 0 or dfs(i, 1) for i in range(n))


# A nested def that calls a sibling needing a capture the caller never names directly:
# `evaluate` binds `n`; `outer` calls `check` which reads `n`, so `outer` must forward it.
def any_valid_pair(s: str) -> int:
    n = len(s)

    def check(i: int, j: int) -> int:
        return 1 if 0 <= i < n and 0 <= j < n and s[i] == s[j] else 0

    def outer(i: int) -> int:
        total = 0
        for j in range(n):
            if check(i, j):
                total += 1
        return total

    return sum(outer(i) for i in range(n))


# False-positive guard: a `lambda` sort key and a threaded `find` call live in the SAME
# statement, but `find` is NOT inside the lambda, so it must still thread.
def sort_then_union(n: int, edges: List[List[int]]) -> int:
    p = list(range(n))

    def find(x: int) -> int:
        if p[x] != x:
            p[x] = find(p[x])
        return p[x]

    for a, b, w in sorted(edges, key=lambda e: e[2]):
        p[find(a)] = find(b)
    return len(set(find(i) for i in range(n)))


# Threaded call in an `if` TEST comprehension: `if any(hasCycle(v) for v):` hoists the
# accumulator loop before the `if`.
def has_any_cycle(n: int, graph: List[List[int]]) -> bool:
    state = [0] * n

    def hasCycle(u: int) -> bool:
        if state[u] == 1:
            return True
        if state[u] == 2:
            return False
        state[u] = 1
        if any(hasCycle(v) for v in graph[u]):
            return True
        state[u] = 2
        return False

    return any(hasCycle(u) for u in range(n) if state[u] == 0)


# Full-slice assignment on a non-name container (`row[:] = ...`): a full slice replaces the
# whole row, equivalent to a plain subscript assign under value semantics.
def reset_grid(grid: List[List[int]], m: int) -> List[List[int]]:
    for i in range(len(grid)):
        grid[i][:] = [0] * m
    return grid


# Threaded call in an `IfExp` CONDITION inside a list comprehension: `find` runs only when
# both endpoints are known (short-circuit `or`), lowered to a per-item guard.
def query_connected(n: int, edges: List[List[int]], queries: List[List[int]]) -> List[int]:
    p = list(range(n))

    def find(x: int) -> int:
        if p[x] != x:
            p[x] = find(p[x])
        return p[x]

    for a, b in edges:
        p[find(a)] = find(b)
    return [0 if a < 0 or b < 0 or find(a) != find(b) else 1 for a, b in queries]
