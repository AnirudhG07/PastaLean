import Mathlib
import PastaLean.PyAPI.CommonProtocols.Iterable

namespace Libraries.bisect

/-- The `a[lo:hi]` window (Python defaults: `lo=0`, `hi=len(a)`, encoded here as `hi < 0`). -/
private def bisectWindow {α : Type} (a : List α) (lo hi : Int) : Nat × List α :=
  let loN := lo.toNat
  let hiN := if hi < 0 then a.length else hi.toNat
  (loN, (a.drop loN).take (hiN - loN))

/-- CPython's bisect binary search over `w` (an `Array` for O(1) indexing). `leftMode` picks the
`bisect_left` rule (`w[mid] < x`) vs `bisect_right` (`¬(x < w[mid])`). Matches CPython exactly,
including on *unsorted* input (where it does a binary search on mis-ordered data), so it can't drift
from the groundtruth the way a `countP` over the whole list would. -/
private partial def bisectSearch {α : Type} [Inhabited α] (leftMode : Bool) (lt : α → α → Bool)
    (w : Array α) (x : α) (lo hi : Nat) : Nat :=
  if lo < hi then
    let mid := (lo + hi) / 2
    let goRight := if leftMode then lt w[mid]! x else !(lt x w[mid]!)
    if goRight then bisectSearch leftMode lt w x (mid + 1) hi
    else bisectSearch leftMode lt w x lo mid
  else lo

/-- `bisect.bisect_left(a, x, lo, hi, key)` with an explicit `key : α → β` mapping each element to the
value compared against `x` — the binary-search-on-answer idiom `bisect_left(range(lo, hi), True,
key=check)`, where the elements are `Int` but `x`/`key` are `Bool`. -/
def pyBisectLeftKey {α β : Type} [Inhabited β] [Ord β]
    (a : List α) (x : β) (key : α → β) (lo : Int := 0) (hi : Int := -1) : Int :=
  let (loN, w) := bisectWindow a lo hi
  let arr := (w.map key).toArray
  Int.ofNat loN + Int.ofNat (bisectSearch true (fun p q => compare p q == Ordering.lt) arr x 0 arr.size)

/-- `bisect.bisect_right(a, x, lo, hi, key)`, keyed form (see `pyBisectLeftKey`). -/
def pyBisectRightKey {α β : Type} [Inhabited β] [Ord β]
    (a : List α) (x : β) (key : α → β) (lo : Int := 0) (hi : Int := -1) : Int :=
  let (loN, w) := bisectWindow a lo hi
  let arr := (w.map key).toArray
  Int.ofNat loN + Int.ofNat (bisectSearch false (fun p q => compare p q == Ordering.lt) arr x 0 arr.size)

/-- Number of elements in `range(start, stop, step)`. -/
private def rangeCount (start stop step : Int) : Nat :=
  if step > 0 then (max 0 ((stop - start + step - 1) / step)).toNat
  else if step < 0 then (max 0 ((start - stop + (-step) - 1) / (-step))).toNat
  else 0

/-- Binary search over `range(start, _, step)` computing `key(start + mid*step)` ON DEMAND — O(log n)
`key` calls, no materialization. This is the `bisect_left(range(1, 10**9), True, key=check)` idiom;
materializing that range (or mapping `key` over all of it, as `pyBisectLeftKey` does) is O(n) and OOMs. -/
private partial def bisectRangeSearch {β : Type} [Inhabited β] (leftMode : Bool) (lt : β → β → Bool)
    (start step : Int) (key : Int → β) (x : β) (lo hi : Nat) : Nat :=
  if lo < hi then
    let mid := (lo + hi) / 2
    let elem := key (start + Int.ofNat mid * step)
    let goRight := if leftMode then lt elem x else !(lt x elem)
    if goRight then bisectRangeSearch leftMode lt start step key x (mid + 1) hi
    else bisectRangeSearch leftMode lt start step key x lo mid
  else lo

/-- Keyed `bisect_left`/`bisect_right` over `range(start, stop, step)` without materializing it. -/
def pyBisectLeftRangeKey {β : Type} [Inhabited β] [Ord β]
    (start stop step : Int) (x : β) (key : Int → β) : Int :=
  Int.ofNat (bisectRangeSearch true (fun p q => compare p q == Ordering.lt)
    start step key x 0 (rangeCount start stop step))

def pyBisectRightRangeKey {β : Type} [Inhabited β] [Ord β]
    (start stop step : Int) (x : β) (key : Int → β) : Int :=
  Int.ofNat (bisectRangeSearch false (fun p q => compare p q == Ordering.lt)
    start step key x 0 (rangeCount start stop step))

/-- `bisect.bisect_left(a, x, lo=0, hi=len(a))`: the leftmost index in `a[lo:hi]` at which `x` keeps
`a` sorted. `Ord` (not `LinearOrder`) so a LIST of tuples — `bisect_left(sorted((s,i) …), (e, -inf))` —
resolves via the lexicographic `Ord (α × β)`. `pyBisectLeft [1, 3, 3, 5] 3 = 1`. -/
def pyBisectLeft {α : Type} [Ord α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : Int :=
  pyBisectLeftKey a x id lo hi

/-- `bisect.bisect_right(a, x, lo=0, hi=len(a))`: the rightmost such index in `a[lo:hi]`.
`pyBisectRight [1, 3, 3, 5] 3 = 3`. -/
def pyBisectRight {α : Type} [Ord α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : Int :=
  pyBisectRightKey a x id lo hi

/-- `bisect.insort_left(a, x, lo=0, hi=len(a))`: insert `x` in place at its `bisect_left` position.
`pyInsortLeft [1, 3, 5] 3 = [1, 3, 3, 5]`. -/
def pyInsortLeft {α : Type} [Ord α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : List α :=
  let i := (pyBisectLeft a x lo hi).toNat
  a.take i ++ x :: a.drop i

/-- `bisect.insort_right(a, x, lo=0, hi=len(a))`: the same at the `bisect_right` position. -/
def pyInsortRight {α : Type} [Ord α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : List α :=
  let i := (pyBisectRight a x lo hi).toNat
  a.take i ++ x :: a.drop i

end Libraries.bisect
