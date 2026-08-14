# A value+mutate method: `union` BOTH mutates self (path/rank updates) AND returns whether it
# merged, used as `if uf.union(a, b):` and `count += uf.union(a, b)`. `find` is likewise a
# value+mutator (path compression writes self.parent AND returns the root), including a nested
# `self.parent[x] = self.find(...)` self-attribute write.
class DSU:
    def __init__(self, n: int):
        self.parent = list(range(n))
        self.rank = [0] * n

    def find(self, x: int) -> int:
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]

    def union(self, a: int, b: int) -> bool:
        ra = self.find(a)
        rb = self.find(b)
        if ra == rb:
            return False
        if self.rank[ra] < self.rank[rb]:
            ra, rb = rb, ra
        self.parent[rb] = ra
        if self.rank[ra] == self.rank[rb]:
            self.rank[ra] += 1
        return True


def count_components(n: int, edges: list[list[int]]) -> int:
    dsu = DSU(n)
    count = n
    for e in edges:
        if dsu.union(e[0], e[1]):
            count -= 1
    return count


def count_merges(n: int, edges: list[list[int]]) -> int:
    dsu = DSU(n)
    merges = 0
    for e in edges:
        merges += dsu.union(e[0], e[1])
    return merges


def count_gated(n: int, edges: list[list[int]], gate: list[int]) -> int:
    # `gate[i] == 1 and dsu.union(...)`: the union (and its mutation) must run ONLY when the gate is
    # open — a value+mutate call inside a short-circuit `and`.
    dsu = DSU(n)
    merges = 0
    for i in range(len(edges)):
        e = edges[i]
        if gate[i] == 1 and dsu.union(e[0], e[1]):
            merges += 1
    return merges


def main():
    print(count_components(5, [[0, 1], [1, 2], [3, 4]]))
    print(count_merges(6, [[0, 1], [2, 3], [4, 5], [1, 2], [0, 2]]))
    print(count_gated(5, [[0, 1], [1, 2], [2, 3], [3, 4]], [1, 0, 1, 0]))


if __name__ == "__main__":
    main()
