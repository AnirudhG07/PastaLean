import Libraries.sortedcontainers.SortedListDef
import Libraries.Behaviour

namespace Libraries.sortedcontainers
open Libraries TypeInfer

/-- `from sortedcontainers import SortedList`: the constructor as a value/member reference lowers to
the sorted-list builder. The instance methods (`add`/`remove`/`bisect_left`/…) are dispatched by the
codegen method layer, since they need the receiver to be recognised as a `SortedList`. -/
def pythonSortedcontainersMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "SortedList" => some ``Libraries.sortedcontainers.pySortedList
  | _ => none

/-- `SortedList(xs)` yields a list of `xs`'s element type (it IS a sorted `List`). -/
def sortedcontainersBehaviour? (member : String) : Option Behaviour :=
  open Behaviour in
  match member with
  | "SortedList" => some (listOf 0)
  | _ => none

/-- A `SortedList` instance method → its runtime function. Codegen consults this ONLY when the
receiver is a known `SortedList` (via its `sortedVars` flag): `add`/`remove`/`discard` collide with
the set methods and must maintain order, and `bisect_left`/`bisect_right`/`bisect` collide with the
`bisect` module functions on a plain list. -/
def sortedListMethod? (attr : String) : Option Lean.Name :=
  match attr with
  | "add"                     => some ``pySortedAdd
  | "remove" | "discard"      => some ``pySortedRemove
  | "bisect_left"             => some ``pyBisectLeft
  | "bisect_right" | "bisect" => some ``pyBisectRight
  | _ => none

end Libraries.sortedcontainers
