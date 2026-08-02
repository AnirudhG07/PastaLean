import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.CycpatternCheck

/-- True iff `needle` occurs as a contiguous run inside `hay`. -/
def isInfixCh (needle hay : List Char) : Bool :=
  (List.range (hay.length + 1)).any (fun i => (hay.drop i).take needle.length == needle)

/-- True iff some rotation of `b` is a substring of `a`. -/
def cycpattern_check (a b : String) : Bool :=
  if a == b then true
  else if b.data == [] then true
  else
    let bd := b.data
    (List.range bd.length).any (fun i => isInfixCh (bd.drop i ++ bd.take i) a.data)

theorem cycpattern_check_correct :
    cycpattern_check "xyzw" "xyw" = false ∧ cycpattern_check "yello" "ell" = true ∧
    cycpattern_check "whattup" "ptut" = false ∧ cycpattern_check "efef" "fee" = true ∧
    cycpattern_check "abab" "aabb" = false ∧ cycpattern_check "winemtt" "tinem" = true := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

/-- General property: every string cyclically matches itself. -/
theorem cycpattern_check_self (a : String) : cycpattern_check a a = true := by
  simp [cycpattern_check]

end PastaBench.humaneval.CycpatternCheck
