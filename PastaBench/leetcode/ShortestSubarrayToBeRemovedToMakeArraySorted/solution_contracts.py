from contracts import *
from typing import List
from bisect import bisect_left


def findLengthOfShortestSubarray(arr: List[int]) -> int:
    Ensures(Result() >= 0)
    Ensures(Result() <= len(arr))

    n = len(arr)
    i, j = (0, n - 1)

    # Find the end of the non-decreasing prefix arr[0...i]
    while i + 1 < n and arr[i] <= arr[i + 1]:
        # This loop is only entered if n >= 2.
        Invariant(0 <= i)
        Invariant(i < n - 1)
        Decreases(n - 1 - i)
        i += 1
    
    # After the loop, i is the index of the last element in the non-decreasing prefix.
    # For any n, 0 <= i <= n. If n > 0, then 0 <= i < n.
    Assert(0 <= i <= n)

    # Find the start of the non-decreasing suffix arr[j...n-1]
    while j - 1 >= 0 and arr[j - 1] <= arr[j]:
        # This loop is only entered if n >= 2.
        Invariant(j >= 0)
        Invariant(j < n)
        Decreases(j)
        j -= 1
        
    # After the loop, j is the index of the first element in the non-decreasing suffix.
    # For any n, -1 <= j < n. If n > 0, then 0 <= j < n.
    Assert(-1 <= j)
    Assert(j < n)

    if i >= j:
        # The non-decreasing prefix and suffix meet or overlap, so the array is sorted.
        return 0
    
    # On this path, i < j, which implies the array is not sorted and n >= 2.
    Assert(i < j)
    Assert(n >= 2)
    Assert(0 <= i < n)
    Assert(0 <= j < n)

    # We can either remove the suffix from i+1, or the prefix until j-1.
    # The lengths are n-(i+1) and j respectively.
    ans = min(n - i - 1, j)
    Assert(0 <= ans)
    Assert(ans <= n)

    # Try to merge a prefix arr[0...l] with a suffix arr[r...n-1].
    for l in range(i + 1):
        Invariant(0 <= l <= i)
        Invariant(0 <= ans <= n)
        Invariant(i < j)

        # For a given prefix ending at arr[l], find the smallest element arr[r]
        # in the non-decreasing suffix (arr[j...]) such that arr[l] <= arr[r].
        # The slice arr[j:n] is guaranteed to be sorted by the second while loop.
        r = bisect_left(arr, arr[l], lo=j)
        
        # bisect_left returns an insertion point, so j <= r <= n.
        Assert(j <= r)
        Assert(r <= n)
        
        # The subarray to remove would be arr[l+1...r-1], of length r - l - 1.
        # This length is non-negative because l <= i < j <= r implies l < r.
        Assert(r - l - 1 >= 0)
        ans = min(ans, r - l - 1)
    
    return ans