import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean
open Libraries
open Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 800000
namespace PastaBench.leetcode.GroupsOfSpecialEquivalentStrings

def numSpecialEquivGroups := fun (words : List String) ↦
  let s :=
    (PastaLean.pySetFromList
        ((PastaLean.pyIter words).map fun word =>
          PastaLean.pyStringJoin ""
            (PastaLean.pySort (PastaLean.pySlice word none none (some (2 : Int))) +ₚ
              PastaLean.pySort (PastaLean.pySlice word (some (1 : Int)) none (some (2 : Int))))) :
      List String)
  PastaLean.pyLen s

attribute [simp] numSpecialEquivGroups

private theorem setFromList_foldl_len_le {α} [BEq α] (xs : List α) :
    ∀ acc : List α,
      (xs.foldl (fun acc x => if acc.contains x then acc else acc ++ [x]) acc).length
        ≤ acc.length + xs.length := by
  induction xs with
  | nil => intro acc; simp
  | cons x rest ih =>
    intro acc
    simp only [List.foldl_cons]
    have hstep : (if acc.contains x then acc else acc ++ [x]).length ≤ acc.length + 1 := by
      split
      · omega
      · simp only [List.length_append, List.length_cons, List.length_nil]; omega
    have hih := ih (if acc.contains x then acc else acc ++ [x])
    simp only [List.length_cons]
    omega

private theorem setFromList_len_le {α} [BEq α] (xs : List α) :
    (pySetFromList xs).length ≤ xs.length := by
  have h := setFromList_foldl_len_le xs []
  simpa [pySetFromList] using h

private theorem setFromList_foldl_mono {α} [BEq α] (xs : List α) :
    ∀ acc : List α,
      acc.length ≤ (xs.foldl (fun acc x => if acc.contains x then acc else acc ++ [x]) acc).length := by
  induction xs with
  | nil => intro acc; simp
  | cons x rest ih =>
    intro acc
    simp only [List.foldl_cons]
    have h1 : acc.length ≤ (if acc.contains x then acc else acc ++ [x]).length := by
      split
      · omega
      · simp only [List.length_append, List.length_cons, List.length_nil]; omega
    exact le_trans h1 (ih _)

private theorem setFromList_len_pos {α} [BEq α] (xs : List α) (h : xs ≠ []) :
    1 ≤ (pySetFromList xs).length := by
  obtain ⟨x, rest, rfl⟩ := List.exists_cons_of_ne_nil h
  have heq : pySetFromList (x :: rest)
      = rest.foldl (fun acc y => if acc.contains y then acc else acc ++ [y]) [x] := rfl
  rw [heq]
  have hm := setFromList_foldl_mono rest [x]
  simpa using hm

theorem numSpecialEquivGroups_correct :
    ∀ (words : List String),
      let s :=
        PastaLean.pySetFromList
          ((PastaLean.pyIter words).map fun word =>
            PastaLean.pyStringJoin ""
              (PastaLean.pySort (PastaLean.pySlice word none none (some (2 : Int))) +ₚ
                PastaLean.pySort (PastaLean.pySlice word (some (1 : Int)) none (some (2 : Int)))))
      PastaLean.pyLen words = (0 : Int) ∨
          PastaLean.pyTruthy
              (PastaLean.pyAll
                ((PastaLean.pyIter words).map fun w => PastaLean.pyLen w == PastaLean.pyLen words⦋(0 : Int)⦌)) =
            true →
        (numSpecialEquivGroups words ≥ (0 : Int) ∧ numSpecialEquivGroups words ≤ PastaLean.pyLen words) ∧
          (PastaLean.pyLen words = (0 : Int) ∨ numSpecialEquivGroups words ≥ (1 : Int)) := by
  intro words s hyp
  set inner : List String :=
    (PastaLean.pyIter words).map (fun word =>
      PastaLean.pyStringJoin ""
        (PastaLean.pySort (PastaLean.pySlice word none none (some (2:Int))) +ₚ
          PastaLean.pySort (PastaLean.pySlice word (some (1:Int)) none (some (2:Int))))) with hinner
  have hdef : numSpecialEquivGroups words = ((pySetFromList inner).length : Int) := rfl
  have hpw : PastaLean.pyLen words = (words.length : Int) := rfl
  have hlen : inner.length = words.length := by
    rw [hinner, List.length_map]; rfl
  rw [hdef, hpw]
  have hle := setFromList_len_le inner
  refine ⟨⟨?_, ?_⟩, ?_⟩
  · exact_mod_cast Nat.zero_le _
  · rw [← hlen]; exact_mod_cast hle
  · rcases Nat.eq_zero_or_pos words.length with hz | hpos
    · left; simp [hz]
    · right
      have hne : inner ≠ [] := List.ne_nil_of_length_pos (by rw [hlen]; exact hpos)
      have hp := setFromList_len_pos inner hne
      exact_mod_cast hp

end PastaBench.leetcode.GroupsOfSpecialEquivalentStrings
