# Three Python semantics that differ from a naive Lean lowering:
# 1. `for x in q` where the body APPENDS to `q` visits the appended items (BFS/topological idiom) —
#    Python re-reads the list each step; a snapshot `for` would miss them.
# 2. `sum(<bool generator>)` is an int (True counts as 1), not a bool.
# 3. a nested `and`/`or` with a non-bool operand in a condition (`a or (b and n)`) truthiness-tests it.
def topo_order_count(n: int, edges: list[list[int]]) -> int:
    g = [[] for _ in range(n)]
    indeg = [0] * n
    for a, b in edges:
        g[b].append(a)
        indeg[a] += 1
    q = [i for i in range(n) if indeg[i] == 0]
    seen = 0
    for i in q:                      # q grows via q.append below
        seen += 1
        for j in g[i]:
            indeg[j] -= 1
            if indeg[j] == 0:
                q.append(j)
    return seen


def count_vowels(s: str) -> int:
    vowels = set('aeiou')
    return sum(c in vowels for c in s)   # sum of bools → int


def feb_days(y: int) -> int:
    # `y % 100` is a truthy int inside the nested `and` — the condition must truthiness-test it.
    return 29 if y % 400 == 0 or (y % 4 == 0 and y % 100) else 28


def greedy_flips(nums: list[int]) -> int:
    # `for i, x in enumerate(nums): nums[i+1] ^= 1` mutates a LATER index; Python's live `enumerate`
    # sees it on the next iteration, so the container must be re-read by index.
    ops = 0
    for i, x in enumerate(nums):
        if x == 0:
            if i + 2 >= len(nums):
                return -1
            nums[i + 1] ^= 1
            nums[i + 2] ^= 1
            ops += 1
    return ops


def flip_invert(image: list[list[int]]) -> list[list[int]]:
    # `for row in image: <mutate row in place>` must write the mutated row back into `image` — the
    # loop var is a value copy under our semantics.
    for row in image:
        row.reverse()
        for i in range(len(row)):
            row[i] ^= 1
    return image


def main():
    print(topo_order_count(4, [[1, 0], [2, 0], [3, 1], [3, 2]]))  # 4 (acyclic)
    print(topo_order_count(2, [[1, 0], [0, 1]]))                  # 0 (cycle)
    print(count_vowels("leetcode"))                               # 4
    print(feb_days(2004), feb_days(1900), feb_days(2000))         # 29 28 29
    print(greedy_flips([0, 1, 1, 1, 0, 0]))                       # 3
    print(flip_invert([[1, 1, 0], [1, 0, 1], [0, 0, 0]]))         # [[1,0,0],[0,1,0],[1,1,1]]


if __name__ == "__main__":
    main()
