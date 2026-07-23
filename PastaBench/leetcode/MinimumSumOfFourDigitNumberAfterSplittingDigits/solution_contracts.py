from contracts import *

def minimumSum(num: int) -> int:
    Requires(1000 <= num < 10000)
    nums = []
    while num:
        nums.append(num % 10)
        num //= 10
    nums.sort()
    return 10 * (nums[0] + nums[1]) + nums[2] + nums[3]