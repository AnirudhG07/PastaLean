import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.GetClosestVowel

private def is_vowel := fun (ch : String) ↦ PastaLean.pyContains "aeiouAEIOU" ch

def get_closest_vowel := fun (word : String) ↦
  (do
    for i in (PastaLean.pyRange (0 : Int) (PastaLean.pyLen word -ₚ (2 : Int)) (-(1 : Int)))do
      let _ := Libraries.passta.pyPassInvariant (decide ((0 : Int) < i))
      let _ := Libraries.passta.pyPassInvariant (decide (i < PastaLean.pyLen word -ₚ (1 : Int)))
      if h_1 :
          (PastaLean.pyTruthy (is_vowel word⦋i⦌) = true ∧
              ¬PastaLean.pyTruthy (is_vowel word⦋i -ₚ (1 : Int)⦌) = true) ∧
            ¬PastaLean.pyTruthy (is_vowel word⦋i +ₚ (1 : Int)⦌) = true then
        let __py_ret_1 := word⦋i⦌
        return __py_ret_1
      else
        let _ := ()
    return "" : Id _)

/-- Non-trivial correctness on the reference examples: returns the rightmost vowel flanked by
two consonants (case sensitive), or the empty string if none exists. -/
theorem get_closest_vowel_probe1 : (get_closest_vowel "yogurt").run = "u" := by native_decide
theorem get_closest_vowel_probe2 : (get_closest_vowel "full").run = "u" := by native_decide
theorem get_closest_vowel_probe3 : (get_closest_vowel "quick").run = "" := by native_decide
theorem get_closest_vowel_probe4 : (get_closest_vowel "ab").run = "" := by native_decide
theorem get_closest_vowel_probe5 : (get_closest_vowel "bad").run = "a" := by native_decide
theorem get_closest_vowel_probe6 : (get_closest_vowel "hello").run = "e" := by native_decide
theorem get_closest_vowel_probe7 : (get_closest_vowel "Above").run = "o" := by native_decide
theorem get_closest_vowel_probe8 : (get_closest_vowel "easy").run = "" := by native_decide

end PastaBench.humaneval.GetClosestVowel
