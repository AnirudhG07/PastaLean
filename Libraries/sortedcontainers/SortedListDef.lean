import Mathlib
import PastaLean.PyAPI.CommonProtocols.Iterable

/-! Python's `sortedcontainers.SortedList`, modelled as an ascending-sorted `List α` (the same
representation `heapq` uses). Operations are O(n log n) rather than the library's O(log n), but
correct. The mutating calls (`add`/`remove`/`discard`/`pop`) lower to reassignments of the list
variable; the read/bisect ops are pure. Because the value IS a `List`, subscript / `len` / `in` /
iteration all come from the ordinary list protocols — only order-maintenance and bisection are new. -/

namespace Libraries.sortedcontainers
open PastaLean

private def sortAsc {α : Type} [Ord α] (xs : List α) : List α :=
  xs.mergeSort (fun a b => (compare a b).isLE)

/-- `SortedList(iterable)` / `SortedList()` — build a sorted list from any iterable (empty for none). -/
def pySortedList {α β : Type} [PyIterable α β] [Ord β] (xs : α) : List β := sortAsc (pyIter xs)

/-- `SortedList()` with no argument — the empty sorted list. -/
def pySortedListEmpty {α : Type} : List α := []

/-- `sl.add(x)` — insert `x`, keeping the list sorted. -/
def pySortedAdd {α : Type} [Ord α] (sl : List α) (x : α) : List α := sortAsc (x :: sl)

/-- `sl.remove(x)` / `sl.discard(x)` — drop the first occurrence of `x` (a no-op if absent, which
matches `discard`; `remove`'s "raise on absent" is not modelled). -/
def pySortedRemove {α : Type} [BEq α] (sl : List α) (x : α) : List α := sl.erase x

/-- `sl.bisect_left(x)` — leftmost index at which `x` could be inserted (the count of elements `< x`). -/
def pyBisectLeft {α : Type} [Ord α] (sl : List α) (x : α) : Int :=
  (sl.filter (fun y => compare y x == Ordering.lt)).length

/-- `sl.bisect_right(x)` / `sl.bisect(x)` — rightmost insertion index (the count of elements `≤ x`). -/
def pyBisectRight {α : Type} [Ord α] (sl : List α) (x : α) : Int :=
  (sl.filter (fun y => compare y x != Ordering.gt)).length

end Libraries.sortedcontainers
