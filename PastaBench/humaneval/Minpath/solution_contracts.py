from contracts import *


def minPath(grid, k):
    """
    Given a grid with N rows and N columns (N >= 2) and a positive integer k, 
    each cell of the grid contains a value. Every integer in the range [1, N * N]
    inclusive appears exactly once on the cells of the grid.

    You have to find the minimum path of length k in the grid. You can start
    from any cell, and in each step you can move to any of the neighbor cells,
    in other words, you can go to cells which share an edge with you current
    cell.
    Please note that a path of length k means visiting exactly k cells (not
    necessarily distinct).
    You CANNOT go off the grid.
    A path A (of length k) is considered less than a path B (of length k) if
    after making the ordered lists of the values on the cells that A and B go
    through (let's call them lst_A and lst_B), lst_A is lexicographically less
    than lst_B, in other words, there exist an integer index i (1 <= i <= k)
    such that lst_A[i] < lst_B[i] and for any j (1 <= j < i) we have
    lst_A[j] = lst_B[j].
    It is guaranteed that the answer is unique.
    Return an ordered list of the values on the cells that the minimum path go through.

    Examples:

        Input: grid = [ [1,2,3], [4,5,6], [7,8,9]], k = 3
        Output: [1, 2, 1]

        Input: grid = [ [5,9,3], [4,1,6], [7,8,2]], k = 1
        Output: [1]
    """
    Requires(k >= 1)
    Requires(len(grid) >= 2)
    Requires(all(len(row) == len(grid) for row in grid))
    # "every integer in [1, N*N] appears exactly once" — in particular 1 is somewhere on the
    # grid, which is what makes the cell found below well defined.
    Requires(all(all(v >= 1 and v <= len(grid) * len(grid) for v in row) for row in grid))
    Requires(any(1 in row for row in grid))

    Ensures(len(Result()) == k)
    # The optimal path oscillates between the cell holding 1 and its cheapest neighbour.
    Ensures(all(Result()[i] == 1 for i in range(0, k, 2)))
    Ensures(all(Result()[i] > 1 for i in range(1, k, 2)))
    Ensures(k < 2 or all(Result()[i] == Result()[1] for i in range(1, k, 2)))
    # Every value emitted is genuinely a value on the grid — the path never invents a cell.
    Ensures(all(any(v in row for row in grid) for v in Result()))
    # The real content: the odd entry is the MINIMUM over the edge-neighbours of the 1-cell,
    # and is attained by one of them. `len(grid)` is used instead of `N` because `N` is bound
    # below this point.
    Ensures(k < 2 or all(
        grid[t // len(grid)][t % len(grid)] != 1
        or all(
            Result()[1] <= grid[u // len(grid)][u % len(grid)]
            for u in range(len(grid) * len(grid))
            if (t // len(grid) == u // len(grid)
                and (t % len(grid) == u % len(grid) + 1
                     or u % len(grid) == t % len(grid) + 1))
            or (t % len(grid) == u % len(grid)
                and (t // len(grid) == u // len(grid) + 1
                     or u // len(grid) == t // len(grid) + 1))
        )
        for t in range(len(grid) * len(grid))
    ))
    Ensures(k < 2 or any(
        grid[t // len(grid)][t % len(grid)] == 1
        and any(
            Result()[1] == grid[u // len(grid)][u % len(grid)]
            for u in range(len(grid) * len(grid))
            if (t // len(grid) == u // len(grid)
                and (t % len(grid) == u % len(grid) + 1
                     or u % len(grid) == t % len(grid) + 1))
            or (t % len(grid) == u % len(grid)
                and (t // len(grid) == u // len(grid) + 1
                     or u // len(grid) == t // len(grid) + 1))
        )
        for t in range(len(grid) * len(grid))
    ))

    N = len(grid)
    x, y = 0, 0
    for i in range(N):
        Invariant(0 <= i)
        Invariant(i <= N)
        # Once a 1 has been seen, (x, y) points at it and stays there.
        Invariant(all(all(grid[r][c] != 1 for c in range(N)) for r in range(i)) or grid[x][y] == 1)
        for j in range(N):
            Invariant(0 <= i)
            Invariant(i < N)
            Invariant(0 <= j)
            Invariant(j <= N)
            Invariant(0 <= x)
            Invariant(x < N)
            Invariant(0 <= y)
            Invariant(y < N)
            if grid[i][j] == 1:
                x, y = i, j

    Assert(0 <= x < N)
    Assert(0 <= y < N)
    Assert(grid[x][y] == 1)

    mn = N * N
    if x > 0: mn = min(mn, grid[x - 1][y])
    if x < N - 1: mn = min(mn, grid[x + 1][y])
    if y > 0: mn = min(mn, grid[x][y - 1])
    if y < N - 1: mn = min(mn, grid[x][y + 1])
    
    Assert(mn > 1)
    Assert(mn <= N * N)

    return [1 if i % 2 == 0 else mn for i in range(k)]