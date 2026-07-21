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

/-- `bisect.bisect_left(a, x, lo=0, hi=len(a))`: the leftmost index in `a[lo:hi]` at which `x` keeps
`a` sorted. `pyBisectLeft [1, 3, 3, 5] 3 = 1`. -/
def pyBisectLeft {α : Type} [LinearOrder α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : Int :=
  let (loN, w) := bisectWindow a lo hi
  let arr := w.toArray
  Int.ofNat loN + Int.ofNat (bisectSearch true (fun p q => decide (p < q)) arr x 0 arr.size)

/-- `bisect.bisect_right(a, x, lo=0, hi=len(a))`: the rightmost such index in `a[lo:hi]`.
`pyBisectRight [1, 3, 3, 5] 3 = 3`. -/
def pyBisectRight {α : Type} [LinearOrder α] [Inhabited α]
    (a : List α) (x : α) (lo : Int := 0) (hi : Int := -1) : Int :=
  let (loN, w) := bisectWindow a lo hi
  let arr := w.toArray
  Int.ofNat loN + Int.ofNat (bisectSearch false (fun p q => decide (p < q)) arr x 0 arr.size)

end Libraries.bisect
