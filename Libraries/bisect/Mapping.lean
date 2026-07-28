import Libraries.bisect.BisectDef
import Libraries.Mutator

namespace Libraries.bisect

/-- Map supported `bisect` members to the Lean runtime helpers they lower to. -/
def pythonBisectMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "bisect_left"  => some ``Libraries.bisect.pyBisectLeft
  | "bisect_right" => some ``Libraries.bisect.pyBisectRight
  -- CPython exports `bisect` as an alias of `bisect_right`.
  | "bisect"       => some ``Libraries.bisect.pyBisectRight
  | _ => none

/-- The `bisect` members that insert into their list argument in place. CPython exports `insort` as
an alias of `insort_right`. -/
def bisectMutator? (member : String) : Option Libraries.LibraryMutator :=
  match member with
  | "insort" | "insort_right" => some { stmtFn := ``pyInsortRight }
  | "insort_left" => some { stmtFn := ``pyInsortLeft }
  | _ => none

end Libraries.bisect
