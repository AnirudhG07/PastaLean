import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.CountNums

-- Faithful re-typing of the generated `judge`: Python reassigns `l` from a list of
-- digit-strings to a list of ints, which Lean cannot express with one binder, so the
-- int list gets its own binder. Result is `1` iff the signed digit sum is positive.
private def _count_nums'judge (x : Int) : Int :=
  let s : List String := PastaLean.pyList (PastaLean.pyStr x)
  let ints : List Int :=
    if s⦋(0 : Int)⦌ = "-" then
      let tail := PastaLean.pySlice s (some (1 : Int)) none none
      let ds := PastaLean.pyList (PastaLean.pyMap PastaLean.pyInt tail)
      PastaLean.pySetItem ds (0 : Int) (-ds⦋(0 : Int)⦌)
    else
      PastaLean.pyList (PastaLean.pyMap PastaLean.pyInt s)
  if PastaLean.pySum ints > (0 : Int) then (1 : Int) else (0 : Int)

def count_nums := fun (arr : List Int) ↦ PastaLean.pySum (PastaLean.pyMap _count_nums'judge arr)

private theorem judge_bound (x : Int) :
    (0 : Int) ≤ _count_nums'judge x ∧ _count_nums'judge x ≤ (1 : Int) := by
  simp only [_count_nums'judge]
  split_ifs <;> omega

private theorem foldl_bound (l : List Int)
    (h : ∀ x ∈ l, (0 : Int) ≤ x ∧ x ≤ 1) (s : Int) :
    s ≤ l.foldl (· + ·) s ∧ l.foldl (· + ·) s ≤ s + (l.length : Int) := by
  induction l generalizing s with
  | nil => simp
  | cons a t ih =>
    have ha := h a (by simp)
    have ht : ∀ x ∈ t, (0 : Int) ≤ x ∧ x ≤ 1 := fun x hx => h x (List.mem_cons_of_mem a hx)
    have hind := ih ht (s + a)
    simp only [List.foldl_cons, List.length_cons, Nat.cast_add, Nat.cast_one]
    omega

theorem count_nums_correct :
    ∀ (arr : List Int),
      (0 : Int) ≤ count_nums arr ∧ count_nums arr ≤ PastaLean.pyLen arr := by
  intro arr
  have hmap : ∀ x ∈ arr.map _count_nums'judge, (0 : Int) ≤ x ∧ x ≤ 1 := by
    intro x hx
    rw [List.mem_map] at hx
    obtain ⟨y, _, rfl⟩ := hx
    exact judge_bound y
  have hb := foldl_bound (arr.map _count_nums'judge) hmap 0
  have hcn : count_nums arr = (arr.map _count_nums'judge).foldl (· + ·) 0 := rfl
  have hlen : PastaLean.pyLen arr = (arr.length : Int) := rfl
  have hml : (arr.map _count_nums'judge).length = arr.length := by simp
  rw [hcn, hlen]
  rw [hml] at hb
  omega

end PastaBench.humaneval.CountNums
