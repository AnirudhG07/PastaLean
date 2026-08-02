import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.ValidDate

/-- Parse mm-dd-yyyy; validate month 1..12 and day against the month's length. -/
def valid_date (date : String) : Bool :=
  match date.splitOn "-" with
  | [ms, ds, _] =>
    match ms.toInt?, ds.toInt? with
    | some m, some d =>
      if m < 1 || m > 12 then false
      else if m == 2 then 1 ≤ d && d ≤ 29
      else if m ∈ [4,6,9,11] then 1 ≤ d && d ≤ 30
      else 1 ≤ d && d ≤ 31
    | _, _ => false
  | _ => false

theorem valid_date_correct :
    valid_date "03-11-2000" = true ∧
    valid_date "15-01-2012" = false ∧
    valid_date "04-0-2040" = false ∧
    valid_date "06-04-2020" = true ∧
    valid_date "01-01-2007" = true ∧
    valid_date "03-32-2011" = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.ValidDate
