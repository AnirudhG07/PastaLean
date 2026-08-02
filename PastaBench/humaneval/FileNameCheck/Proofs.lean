import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean Libraries Std.Do

set_option linter.all false
set_option maxHeartbeats 800000

namespace PastaBench.humaneval.FileNameCheck

def numDigits (s : String) : Nat := (s.toList.filter (fun c => c.isDigit)).length
def dotCount (s : String) : Nat := (s.toList.filter (fun c => c == '.')).length

def valid (fileName : String) : Bool :=
  let parts := fileName.splitOn "."
  (decide (numDigits fileName ≤ 3)) &&
  (dotCount fileName == 1) &&
  (match parts with
   | [base, ext] =>
     (match base.toList with
      | c :: _ => c.isAlpha
      | [] => false) &&
     (ext == "txt" || ext == "exe" || ext == "dll")
   | _ => false)

def fileNameCheck (fileName : String) : String :=
  if valid fileName then "Yes" else "No"

theorem fileNameCheck_correct (fileName : String) :
    (fileNameCheck fileName = "Yes") ↔ valid fileName = true := by
  unfold fileNameCheck
  by_cases h : valid fileName = true <;> simp [h]

theorem fileNameCheck_range (fileName : String) :
    fileNameCheck fileName = "Yes" ∨ fileNameCheck fileName = "No" := by
  unfold fileNameCheck; split <;> simp

example : fileNameCheck "example.txt" = "Yes" := by native_decide
example : fileNameCheck "1example.dll" = "No" := by native_decide

end PastaBench.humaneval.FileNameCheck
