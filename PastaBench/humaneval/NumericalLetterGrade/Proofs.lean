import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.NumericalLetterGrade

private def to_letter_grade := fun (score : Rat) ↦
  Id.run
    (do
      if h_1 : score = (4.0 : Rat) then return "A+"
      else if h_2 : score > (3.7 : Rat) then return "A"
      else if h_3 : score > (3.3 : Rat) then return "A-"
      else if h_4 : score > (3.0 : Rat) then return "B+"
      else if h_5 : score > (2.7 : Rat) then return "B"
      else if h_6 : score > (2.3 : Rat) then return "B-"
      else if h_7 : score > (2.0 : Rat) then return "C+"
      else if h_8 : score > (1.7 : Rat) then return "C"
      else if h_9 : score > (1.3 : Rat) then return "C-"
      else if h_10 : score > (1.0 : Rat) then return "D+"
      else if h_11 : score > (0.7 : Rat) then return "D"
      else if h_12 : score > (0.0 : Rat) then return "D-"
      else return "E")

def numerical_letter_grade := fun (grades : List Rat) ↦
  (PastaLean.pyIter grades).map fun x => to_letter_grade x

/-- Correctness: maps each GPA to its letter grade per the grading table, checked on
    the reference test cases. -/
theorem numerical_letter_grade_correct :
    numerical_letter_grade [4.0, 3, 1.7, 2, 3.5] = ["A+", "B", "C-", "C", "A-"] ∧
    numerical_letter_grade [1.2] = ["D+"] ∧
    numerical_letter_grade [0.5] = ["D-"] ∧
    numerical_letter_grade [0.0] = ["E"] ∧
    numerical_letter_grade [1, 0.3, 1.5, 2.8, 3.3] = ["D", "D-", "C-", "B", "B+"] := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.NumericalLetterGrade
