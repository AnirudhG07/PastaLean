import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

namespace PastaBench.humaneval.Bf

def planets : List String :=
  ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]

def bf := fun planet1 ↦ fun planet2 ↦
  Id.run
    (do
      let mut planets : List String :=
        ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]
      if h_1 : !(PastaLean.pyContains planets planet1) ∨ !(PastaLean.pyContains planets planet2) then
        let __py_ret_1 := []
        return __py_ret_1
      else
        let _ := ()
      let __unpack_value_1 := (PastaLean.pyIndex planets planet1, PastaLean.pyIndex planets planet2)
      let __unpack_pair_1 := __unpack_value_1
      let mut i1 : Int := Prod.fst __unpack_pair_1
      let mut i2 : Int := Prod.snd __unpack_pair_1
      if h_2 : i1 > i2 then
        let __unpack_value_2 := (i2, i1)
        let __unpack_pair_2 := __unpack_value_2
        i1 := Prod.fst __unpack_pair_2
        i2 := Prod.snd __unpack_pair_2
      else
        let _ := ()
      let __py_ret_1 := PastaLean.pyList (PastaLean.pySlice planets (some (i1 +ₚ (1 : Int))) (some i2) none)
      return __py_ret_1)

/-- If the first argument is not a valid planet name, `bf` returns the empty list. -/
theorem bf_invalid_empty (planet1 planet2 : String)
    (h : PastaLean.pyContains planets planet1 = false) : bf planet1 planet2 = [] := by
  simp only [bf, planets, Id.run] at *
  simp only [h, Bool.not_false, true_or, dif_pos]
  rfl

end PastaBench.humaneval.Bf
