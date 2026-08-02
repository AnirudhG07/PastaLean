import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FlipCase

def flip_case := fun (string : String) ↦
  PastaLean.pyStringJoin "" (PastaLean.pyMap (fun x ↦ PastaLean.pyStringSwapcase x) string)

/-- `swapcase` preserves string length (each char maps to another single char). -/
theorem swapcase_length (s : String) :
    (PastaLean.pyStringSwapcase s).length = s.length := by
  simp only [PastaLean.pyStringSwapcase, String.length_ofList, List.length_map,
    String.length_toList]

/-- Intercalating with the empty separator gives length = sum of the parts' lengths. -/
theorem intercalate_empty_length (L : List String) :
    (String.intercalate "" L).length = (L.map String.length).sum := by
  induction L with
  | nil => simp [String.intercalate_nil]
  | cons a t ih =>
    cases t with
    | nil => simp [String.intercalate_singleton]
    | cons b u =>
      rw [String.intercalate_cons_cons]
      simp only [String.length_append, String.length_empty, List.map_cons, List.sum_cons, ih]
      omega

/-- Sum of a list under a function that is always `1` equals the list length. -/
theorem sum_const_one {α : Type} (l : List α) (f : α → Nat) (h : ∀ x, f x = 1) :
    (l.map f).sum = l.length := by
  induction l with
  | nil => simp
  | cons a t ih => simp only [List.map_cons, List.sum_cons, h a, ih, List.length_cons]; omega

/-- Correctness: `flip_case` preserves the length of its input string. -/
theorem flip_case_length : ∀ (string : String),
    PastaLean.pyLen (flip_case string) = PastaLean.pyLen string := by
  intro string
  have hlen : (flip_case string).length = string.length := by
    have h1 : flip_case string
        = String.intercalate ""
            ((string.toList.map (·.toString)).map (fun x ↦ PastaLean.pyStringSwapcase x)) := by
      simp [flip_case, PastaLean.pyStringJoin, PastaLean.pyMap, PastaLean.pyIter,
        PyStringJoin.toJoinString, PyIterable.toPyList]
    rw [h1, intercalate_empty_length]
    simp only [List.map_map]
    rw [sum_const_one _ _ (by
      intro c
      simp only [Function.comp, swapcase_length]
      simp)]
    simp [String.length_toList]
  simp only [pyLen, PyLen.pyLen]
  omega

end PastaBench.humaneval.FlipCase
