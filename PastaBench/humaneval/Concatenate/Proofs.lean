import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Concatenate

def concatenate := fun (strings : List String) ↦ PastaLean.pyStringJoin "" strings

/-- With an empty separator, `intercalate` distributes over `cons` as a plain append. -/
private theorem interc_cons : ∀ (as : List String) (a : String),
    String.intercalate "" (a :: as) = a ++ String.intercalate "" as := by
  intro as
  induction as with
  | nil => intro a; simp
  | cons b bs ih =>
    intro a
    calc String.intercalate "" (a :: b :: bs)
        = String.intercalate "" ((a ++ "" ++ b) :: bs) := rfl
      _ = String.intercalate "" ((a ++ b) :: bs) := by rw [String.append_empty]
      _ = (a ++ b) ++ String.intercalate "" bs := ih (a ++ b)
      _ = a ++ (b ++ String.intercalate "" bs) := by rw [String.append_assoc]
      _ = a ++ String.intercalate "" (b :: bs) := by rw [ih b]

private theorem interc_len (l : List String) :
    (String.intercalate "" l).length = (l.map String.length).sum := by
  induction l with
  | nil => simp
  | cons a as ih =>
    rw [interc_cons as a, String.length_append, ih]
    simp [List.map_cons, List.sum_cons]

/-- Concatenating a list of strings yields a string whose length is the sum of the fragment
lengths — the natural correctness property of `"".join(strings)`. -/
theorem concatenate_correct : ∀ (strings : List String),
    PastaLean.pyLen (concatenate strings) = ((strings.map String.length).sum : Int) := by
  intro strings
  simp only [concatenate, PastaLean.pyStringJoin, PastaLean.pyLen, PyLen.pyLen, PastaLean.pyIter,
    PyIterable.toPyList, PyStringJoin.toJoinString, List.map_id, id_eq]
  rw [interc_len]

end PastaBench.humaneval.Concatenate
