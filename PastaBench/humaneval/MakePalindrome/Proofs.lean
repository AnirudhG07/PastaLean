import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.MakePalindrome

def is_palindrome := fun (string : String) ↦ string == PastaLean.pySlice string none none (some (-(1 : Int)))

def make_palindrome := fun (string : String) ↦
  (do
    if h_1 : PastaLean.pyTruthy (is_palindrome string) then
      return string
    else
      let _ := ()
    for i in (PastaLean.pyRange (PastaLean.pyLen string))do
      if h_2 : PastaLean.pyTruthy (is_palindrome (PastaLean.pySlice string (some i) none none)) then
        let __py_ret_1 := string +ₚ PastaLean.pySlice string (some (i -ₚ (1 : Int))) none (some (-(1 : Int)))
        return __py_ret_1
      else
        let _ := ()
    return default : Id _)

-- Shortest palindrome that starts with `string`.
theorem make_palindrome_correct :
    (make_palindrome "").run = ""
      ∧ (make_palindrome "x").run = "x"
      ∧ (make_palindrome "xyz").run = "xyzyx"
      ∧ (make_palindrome "xyx").run = "xyx"
      ∧ (make_palindrome "jerry").run = "jerryrrej"
      ∧ (make_palindrome "race").run = "racecar"
      ∧ (make_palindrome "level").run = "level" := by
  native_decide

end PastaBench.humaneval.MakePalindrome
