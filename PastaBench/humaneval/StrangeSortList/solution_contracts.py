from contracts import *

def strange_sort_list(lst):
    '''
    Given list of integers, return list in strange order.
    Strange sorting, is when you start with the minimum value,
    then maximum of the remaining integers, then minimum and so on.

    Examples:
    strange_sort_list([1, 2, 3, 4]) == [1, 4, 2, 3]
    strange_sort_list([5, 5, 5, 5]) == [5, 5, 5, 5]
    strange_sort_list([]) == []
    '''
    # 1-2. The result is a permutation of the input (same length, same multiset).
    Ensures(len(Result()) == len(lst))
    Ensures(sorted(Result()) == sorted(lst))
    # 3-4. The interleaving itself: even slots take the k-th smallest, odd slots the k-th largest.
    #      Together with (1-2) this pins the result down to exactly one list.
    Ensures(all(Result()[2 * k] == sorted(lst)[k] for k in range(len(lst) // 2)))
    Ensures(all(Result()[2 * k + 1] == sorted(lst)[len(lst) - 1 - k] for k in range(len(lst) // 2)))
    # 5. An odd-length input leaves its median in the final slot.
    Ensures(len(lst) % 2 == 0 or Result()[len(lst) - 1] == sorted(lst)[len(lst) // 2])

    sorted_list = sorted(lst)
    Assert(sorted(lst) == sorted_list)
    Assert(len(sorted_list) == len(lst))

    ans, i, j = [], 0, len(sorted_list) - 1
    while i < j:
        # Loop invariants capture the state of the partitioning:
        # 1. Pointers `i` and `j` move inwards from the ends of `sorted_list`.
        Invariant(0 <= i)
        Invariant(j < len(sorted_list))
        # 2. `i` and `j` don't cross until the loop terminates.
        Invariant(i <= j + 1)
        # 3. The pointers maintain a symmetric relationship.
        Invariant(i + j == len(sorted_list) - 1)
        # 4. The length of the result list `ans` is twice the number of pairs taken.
        Invariant(len(ans) == 2 * i)
        # 5. The core permutation property: elements already in `ans` plus the
        #    unprocessed elements between `i` and `j` constitute the original sorted list.
        Invariant(sorted(ans + sorted_list[i : j + 1]) == sorted_list)
        # 6. The index-style invariant that turns into Ensures 3-4 at loop exit: the first `i`
        #    pairs already placed are the i smallest / i largest, in alternating slots.
        Invariant(all(ans[2 * k] == sorted_list[k] for k in range(i)))
        Invariant(all(ans[2 * k + 1] == sorted_list[len(sorted_list) - 1 - k] for k in range(i)))
        # Termination: the gap between `i` and `j` shrinks.
        Decreases(j - i)

        ans.append(sorted_list[i])
        ans.append(sorted_list[j])
        i += 1
        j -= 1

    # At loop exit, `i >= j`. From the invariant `i <= j + 1`, we know
    # that either `i == j` (for odd-length lists) or `i == j + 1` (for even-length lists).
    Assert(i == j or i == j + 1)
    
    if i == j: 
        ans.append(sorted_list[i])

    # After handling the potential middle element, `ans` must be a permutation of `sorted_list`.
    Assert(sorted(ans) == sorted_list)
    return ans