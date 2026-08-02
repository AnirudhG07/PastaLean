import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.StrongestExtension

private def _Strongest_Extension'strength := fun (s : String) ↦
  Id.run (do
    let __unpack_value_1 := ((0 : Int), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut CAP : Int := Prod.fst __unpack_pair_1
    let mut SM : Int := Prod.snd __unpack_pair_1
    for ch in (PastaLean.pyIter s)do
      let _ := Libraries.passta.pyPassInvariant (decide (CAP ≥ (0 : Int)))
      let _ := Libraries.passta.pyPassInvariant (decide (SM ≥ (0 : Int)))
      if h_1 : PastaLean.pyTruthy (PastaLean.pyIsUpper ch) then 
        CAP := CAP +ₚ (1 : Int)
      else
        let _ := ()
      if h_2 : PastaLean.pyTruthy (PastaLean.pyIsLower ch) then 
        SM := SM +ₚ (1 : Int)
      else
        let _ := ()
    let __py_ret_1 := CAP -ₚ SM
    return __py_ret_1)

def Strongest_Extension := fun (class_name : String) ↦ fun (extensions : List String) ↦
  (do
    let mut max_strength := PastaLean.pyMax (PastaLean.pyMap _Strongest_Extension'strength extensions)
    for e in (PastaLean.pyIter extensions)do
      if h_1 : _Strongest_Extension'strength e = max_strength then 
        -- Bridge assertion: By finding an `e` where `strength(e) == max_strength`,
        -- we have found an element whose strength is equal to the overall maximum.
        -- This fact is needed to prove the postcondition.
        let _ :=
          Libraries.passta.pyPassAssert
            (_Strongest_Extension'strength e ==
              PastaLean.pyMax (PastaLean.pyMap _Strongest_Extension'strength extensions))
        let __py_ret_1 := class_name +ₚ "." +ₚ e
        return __py_ret_1
      else
        let _ := ()
    return default : Id _)

/-- Returns `ClassName.Extension` for the strongest (CAP-SM) extension, first on ties. -/
theorem strongest_extension_examples :
    (Strongest_Extension "my_class" ["AA", "Be", "CC"]).run = "my_class.AA" ∧
    (Strongest_Extension "Slices" ["SErviNGSliCes", "Cheese", "StuFfed"]).run
        = "Slices.SErviNGSliCes" := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.StrongestExtension
