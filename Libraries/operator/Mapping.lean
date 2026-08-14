import Libraries.operator.OperatorDef

namespace Libraries.operator

/-- Map supported `operator` members to the Lean runtime functions they lower to, so a bare
`operator.xor` / `xor` (from `from operator import *`) passed as a value resolves to the Python
semantics rather than falling through to Lean's `Bool`-only `xor`. -/
def pythonOperatorMemberMap? (member : String) : Option Lean.Name :=
  match member with
  | "xor"      => some ``PastaLean.pyBitXor
  | "or_"      => some ``PastaLean.pyBitOr
  | "and_"     => some ``PastaLean.pyBitAnd
  | "add"      => some ``pyOperatorAdd
  | "sub"      => some ``pyOperatorSub
  | "mul"      => some ``pyOperatorMul
  | "mod"      => some ``pyOperatorMod
  | "floordiv" => some ``pyOperatorFloorDiv
  | "truediv"  => some ``pyOperatorTrueDiv
  | "pow"      => some ``pyOperatorPow
  | _ => none

end Libraries.operator
