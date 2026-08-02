import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.GetRow

/-- Coordinates (row, col) of every `x` in the ragged matrix, rows ascending, cols descending. -/
def get_row (lst : List (List Int)) (x : Int) : List (Int × Int) :=
  let coords : List (Int × Int) := (lst.zipIdx).flatMap (fun (row, i) =>
    (row.zipIdx).filterMap (fun (v, j) => if v == x then some ((i : Int), (j : Int)) else none))
  coords.mergeSort (fun (a b : Int × Int) => if a.1 == b.1 then a.2 ≥ b.2 else a.1 ≤ b.1)

theorem get_row_correct :
    get_row [[1,2,3,4,5,6],[1,2,3,4,1,6],[1,2,3,4,5,1]] 1
      = [(0,0),(1,4),(1,0),(2,5),(2,0)] ∧
    get_row [[1,2,3,4,5,6],[1,2,3,4,5,6],[1,2,3,4,5,6],[1,2,3,4,5,6],[1,2,3,4,5,6],[1,2,3,4,5,6]] 2
      = [(0,1),(1,1),(2,1),(3,1),(4,1),(5,1)] := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.GetRow
