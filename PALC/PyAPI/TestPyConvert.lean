import PastaLean

open PastaLean Lean

/-!
`@[py_convert "name"]` lets a user support a new Python conversion `a = name(s)` by tagging ONE Lean
function — no edit to `pythonBuiltinMap?`. The name pins the target type; the tagged function stays
open on its *source* via its own typeclass, so a new source type is just another instance.
-/

/-- A toy conversion open on its source: `codes(x)` yields the code points of any iterable of chars. -/
class ToCodes (α : Type) where
  toCodes : α → List Int

instance : ToCodes String where toCodes s := s.toList.map (fun c => (c.toNat : Int))
instance : ToCodes (List Char) where toCodes cs := cs.map (fun c => (c.toNat : Int))

@[py_convert "codes"]
def pyCodes {α : Type} [ToCodes α] (x : α) : List Int := ToCodes.toCodes x

-- The attribute registered "codes" → the function; a second source type needs only its instance.
/-- info: some `pyCodes -/
#guard_msgs in
#eval do return (← pyConvertRegistered? "codes")

/-- info: none -/
#guard_msgs in
#eval do return (← pyConvertRegistered? "not_a_registered_conversion")

/-- info: [104, 105] -/
#guard_msgs in
#eval pyCodes "hi"

/-- info: [104, 105] -/
#guard_msgs in
#eval pyCodes ['h', 'i']
