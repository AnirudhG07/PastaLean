import Libraries.bisect.BisectDef
import Libraries.Mutator
import Libraries.Behaviour

namespace Libraries.bisect
open Libraries

/-- Map supported `bisect` members to the Lean runtime helpers they lower to. -/
def pythonBisectMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "bisect_left"  => some ``Libraries.bisect.pyBisectLeft
  | "bisect_right" => some ``Libraries.bisect.pyBisectRight
  -- CPython exports `bisect` as an alias of `bisect_right`.
  | "bisect"       => some ``Libraries.bisect.pyBisectRight
  | _ => none

/-- Behaviour of `bisect` members: `insort`/`insort_left`/`insort_right` insert into their list
argument in place (`mutator`, read by the code generator). CPython exports `insort` as an alias of
`insort_right`. -/
def bisectBehaviour? (member : String) : Option Behaviour :=
  match member with
  | "insort" | "insort_right" => some { mutator := some { stmtFn := ``pyInsortRight } }
  | "insort_left"             => some { mutator := some { stmtFn := ``pyInsortLeft } }
  -- With a `key=` callback, route to the keyed shim variant (binary-search-on-answer).
  | "bisect_left"             => some { keyedVariant := some ``pyBisectLeftKey }
  | "bisect" | "bisect_right" => some { keyedVariant := some ``pyBisectRightKey }
  | _ => none

end Libraries.bisect
