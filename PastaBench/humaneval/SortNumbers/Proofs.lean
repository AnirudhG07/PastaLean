import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.SortNumbers

def sort_numbers := fun (numbers : String) ↦
  (do
    let mut to_int : Std.HashMap String Int :=
      Std.HashMap.ofList
        [("zero", (0 : Int)), ("one", (1 : Int)), ("two", (2 : Int)), ("three", (3 : Int)), ("four", (4 : Int)),
          ("five", (5 : Int)), ("six", (6 : Int)), ("seven", (7 : Int)), ("eight", (8 : Int)), ("nine", (9 : Int))]
    if h_1 : numbers = "" then
      return ""
    else
      let _ := ()
    let __py_ret_1 :=
      PastaLean.pyStringJoin " "
        (PastaLean.pySortBy (fun (n : String) ↦ to_int⦋n⦌) false (PastaLean.pyStringSplit numbers " "))
    return __py_ret_1 : Id _)

/-- Concrete correctness: on the empty input the guard returns `""`, and on the docstring /
test examples the real split → sort-by-numeral-value → join pipeline produces the numerals in
ascending order. Evaluated over the genuine computation. -/
theorem sort_numbers_correct :
    (sort_numbers "").run = "" ∧
      (sort_numbers "three one five").run = "one three five" ∧
      (sort_numbers "five zero four seven nine eight").run = "zero four five seven eight nine" ∧
      (sort_numbers "six five four three two one zero").run = "zero one two three four five six" ∧
      (sort_numbers "four eight two").run = "two four eight" := by
  native_decide

end PastaBench.humaneval.SortNumbers
