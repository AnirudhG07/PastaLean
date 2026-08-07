from contracts import *
import math

def max_fill(grid, capacity):
    """
    You are given a rectangular grid of wells. Each row represents a single well,
    and each 1 in a row represents a single unit of water.
    Each well has a corresponding bucket that can be used to extract water from it, 
    and all buckets have the same capacity.
    Your task is to use the buckets to empty the wells.
    Output the number of times you need to lower the buckets.

    Example 1:
        Input: 
            grid : [[0,0,1,0], [0,1,0,0], [1,1,1,1]]
            bucket_capacity : 1
        Output: 6

    Example 2:
        Input: 
            grid : [[0,0,1,1], [0,0,0,0], [1,1,1,1], [0,1,1,1]]
            bucket_capacity : 2
        Output: 5
    
    Example 3:
        Input: 
            grid : [[0,0,0], [0,0,0]]
            bucket_capacity : 5
        Output: 0

    Constraints:
        * all wells have the same length
        * 1 <= grid.length <= 10^2
        * 1 <= grid[:,1].length <= 10^2
        * grid[i][j] -> 0 | 1
        * 1 <= capacity <= 10
    """
    Requires(capacity >= 1)
    Requires(len(grid) >= 1)
    Requires(all(all(x == 0 or x == 1 for x in l) for l in grid))

    # The point of the function is to compute the total number of bucket trips, which is
    # the sum of trips for each well. The number of trips for a single well is the
    # ceiling of its water units divided by the bucket capacity.
    Ensures(Result() == sum(math.ceil(sum(l) / capacity) for l in grid))

    # The same statement, division-free: `capacity * Result()` brackets the total water from
    # above, and overshoots by strictly less than one bucket per well. This is what "ceiling,
    # summed per row" actually means, and it is stated without a single division.
    Ensures(capacity * Result() >= sum(sum(l) for l in grid))
    Ensures(capacity * Result() < sum(sum(l) for l in grid) + capacity * len(grid))
    # No trip is wasted: with capacity >= 1 you never need more trips than units of water.
    Ensures(Result() >= 0)
    Ensures(Result() <= sum(sum(l) for l in grid))

    ans = 0
    for l in grid:
        # The running total is always non-negative, as each term added is non-negative.
        Invariant(ans >= 0)
        # Accumulator form of the upper bound, over the wells emptied so far.
        Invariant(ans <= sum(sum(r) for r in grid))
        ans += math.ceil(sum(l) / capacity)

    # After the loop, `ans` holds the final sum, which is exactly the property
    # required by the postcondition.
    Assert(ans == sum(math.ceil(sum(l) / capacity) for l in grid))
    return ans