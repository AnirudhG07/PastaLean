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

end Libraries.sortedcontainers
