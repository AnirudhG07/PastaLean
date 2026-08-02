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
    Ensures(len(Result()) == len(lst))
    Ensures(sorted(Result()) == sorted(lst))

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