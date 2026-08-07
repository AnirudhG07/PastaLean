from contracts import *


def minSubArraySum(nums):
    """
    Given an array of integers nums, find the minimum sum of any non-empty sub-array
    of nums.
    Example
    minSubArraySum([2, 3, 4, 1, 2, 4]) == 1
    minSubArraySum([-1, -2, -3]) == -6
    """
    Requires(len(nums) > 0)
    # THE POINT, both directions. Lower bound: the answer is <= the sum of EVERY non-empty
    # contiguous sub-array nums[i:j].
    Ensures(all(
        all(Result() <= sum(nums[i:j]) for j in range(i + 1, len(nums) + 1))
        for i in range(len(nums))
    ))
    # Tightness: the answer is actually attained by some non-empty contiguous sub-array, so it is
    # the minimum and not merely a lower bound.
    Ensures(any(
        any(Result() == sum(nums[i:j]) for j in range(i + 1, len(nums) + 1))
        for i in range(len(nums))
    ))
    # If all numbers are non-negative, the minimum sum is just the smallest element.
    Ensures(not all(x >= 0 for x in nums) or (Result() == min(nums)))
    # If there is at least one negative number, the minimum sum must be negative.
    Ensures(all(x >= 0 for x in nums) or (Result() < 0))

    if all(x >= 0 for x in nums):
        return min(nums)

    # In this branch, we know there is at least one negative number.
    Assert(any(x < 0 for x in nums))
    s, ans = 0, 0
    for x in nums:
        # The running sum `s` from the last reset point is always non-positive on entry.
        Invariant(s <= 0)
        # The overall minimum found so far `ans` is always non-positive.
        Invariant(ans <= 0)
        # `ans` never exceeds the running suffix sum, so the candidate `s` is always already covered.
        Invariant(ans <= s)

        s += x
        ans = min(ans, s)
        if s >= 0:
            s = 0

    # The invariant `ans <= 0` holds. Because we know there is a negative number
    # in the input, the minimum sum must be strictly negative.
    Assert(ans < 0)
    return ans