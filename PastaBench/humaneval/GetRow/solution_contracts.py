from typing import *
from contracts import *

def get_row(lst: List[List[int]], x: int):
    """
    You are given a 2 dimensional data, as a nested lists,
    which is similar to matrix, however, unlike matrices,
    each row may contain a different number of columns.
    Given lst, and integer x, find integers x in the list,
    and return list of tuples, [(x1, y1), (x2, y2) ...] such that
    each tuple is a coordinate - (row, columns), starting with 0.
    Sort coordinates initially by rows in ascending order.
    Also, sort coordinates of the row by columns in descending order.

    Examples:
    get_row([
      [1,2,3,4,5,6],
      [1,2,3,4,1,6],
      [1,2,3,4,5,1]
    ], 1) == [(0, 0), (1, 4), (1, 0), (2, 5), (2, 0)]
    get_row([], 1) == []
    get_row([[], [1], [1, 2, 3]], 3) == [(2, 2)]
    """
    # 1. Every returned pair is a legal coordinate of the ragged grid ...
    Ensures(all(0 <= p[0] and p[0] < len(lst) for p in Result()))
    Ensures(all(0 <= p[1] and p[1] < len(lst[p[0]]) for p in Result()))
    # 2. ... and the cell it names really holds x (soundness).
    Ensures(all(lst[p[0]][p[1]] == x for p in Result()))
    # 3. Nothing is missed: exactly as many coordinates as there are occurrences of x
    #    (completeness — with (2) and the strict ordering in (4), this pins Result() down).
    Ensures(len(Result()) == sum(row.count(x) for row in lst))
    # 4. The required order: rows ascending, and within a row columns strictly descending.
    Ensures(all(
        Result()[k][0] < Result()[k + 1][0]
        or (Result()[k][0] == Result()[k + 1][0] and Result()[k][1] > Result()[k + 1][1])
        for k in range(len(Result()) - 1)))

    res = []
    for i, l in enumerate(lst):
        Invariant(0 <= i)
        Invariant(i < len(lst))
        # Bridge the row alias so the inner `l[j]` reads are `lst[i][j]` reads.
        Invariant(l == lst[i])
        # Accumulator: everything collected so far is a valid coordinate holding x, and the
        # rows already scanned have been fully accounted for.
        Invariant(all(lst[p[0]][p[1]] == x for p in res))
        Invariant(len(res) == sum(lst[r].count(x) for r in range(i)))
        Decreases(len(lst) - i)
        for j in range(len(l) - 1, -1, -1):
            Invariant(0 <= j)
            Invariant(j < len(l))
            Invariant(all(lst[p[0]][p[1]] == x for p in res))
            Decreases(j)
            if l[j] == x:
                res.append((i, j))
    return res
