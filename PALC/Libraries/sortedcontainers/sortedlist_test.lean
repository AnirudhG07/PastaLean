import Libraries.sortedcontainers.SortedListDef

namespace Libraries.sortedcontainers

-- `add` keeps the list sorted and allows duplicates.
/-- info: [2, 5, 5] -/
#guard_msgs in
#eval pySortedAdd (pySortedAdd (pySortedAdd ([] : List Int) 5) 2) 5

-- `SortedList(iterable)` sorts its argument.
/-- info: [1, 1, 2, 3] -/
#guard_msgs in
#eval pySortedList [3, 1, 2, 1]

-- `bisect_left` = count of elements `< x` (leftmost insertion index).
/-- info: 1 -/
#guard_msgs in
#eval pyBisectLeft [2, 5, 5, 8] (5 : Int)

-- `bisect_right` = count of elements `≤ x` (rightmost insertion index).
/-- info: 3 -/
#guard_msgs in
#eval pyBisectRight [2, 5, 5, 8] (5 : Int)

-- `bisect_left` past a gap counts all smaller elements.
/-- info: 3 -/
#guard_msgs in
#eval pyBisectLeft [2, 5, 5, 8] (6 : Int)

-- `remove` drops the first occurrence only.
/-- info: [1, 2, 3] -/
#guard_msgs in
#eval pySortedRemove [1, 1, 2, 3] (1 : Int)

end Libraries.sortedcontainers
