import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 1600000

namespace PastaBench.humaneval.HasCloseElements

/-- `all`/`any` over a `pyRange` map reduces to a bounded quantifier over the indices. -/
theorem pyAll_pyRange_map (n : Int) (f : Int → Bool) :
    pyAll ((pyRange n).map f) = true ↔ ∀ k : Int, 0 ≤ k → k < n → f k = true := by
  have hpb : ∀ b : Bool, pyBool b = b := fun _ => rfl
  simp only [pyAll, PyAll.pyAll, pyIter, PyIterable.toPyList, id_eq, List.all_map,
    Function.comp, hpb, pyRange_eq_ofNat, List.all_eq_true, List.mem_map, List.mem_range,
    Int.ofNat_eq_natCast, forall_exists_index, and_imp, forall_apply_eq_imp_iff₂]
  constructor
  · intro h k hk0 hkn
    have hlt : k.toNat < n.toNat := by omega
    have := h k.toNat hlt
    rwa [Int.natCast_toNat_eq_self.mpr hk0] at this
  · intro h m hm
    exact h (m : Int) (by positivity) (by omega)

/-- The loop cursor value over `List.range` equals its position, i.e. the element split out
of `List.range M` at the boundary is the prefix length. -/
theorem range_split {M cur : Nat} {pref suff : List Nat}
    (h : List.range M = pref ++ cur :: suff) : cur = pref.length := by
  have hlen : pref.length < M := by
    have h2 : (pref ++ cur :: suff).length = M := by rw [← h, List.length_range]
    simp only [List.length_append, List.length_cons] at h2; omega
  have key : (List.range M)[pref.length]? = some cur := by
    rw [h, List.getElem?_append_right (le_refl pref.length)]; simp
  rw [List.getElem?_range hlen] at key
  simpa using key.symm

def has_close_elements := fun (numbers : List Rat) ↦ fun (threshold : Rat) ↦
  (do
    let mut sorted_numbers := PastaLean.pySort numbers
    for i in (PastaLean.pyRange (PastaLean.pyLen sorted_numbers -ₚ (1 : Int)))do
      if h_1 : sorted_numbers⦋i +ₚ (1 : Int)⦌ -ₚ sorted_numbers⦋i⦌ < threshold then
        return Bool.true
      else
        let _ := ()
    return Bool.false : Id _)

/-- Non-trivial correctness (soundness of the negative answer): if `has_close_elements`
returns `False`, then *every* adjacent pair in the sorted list is at least `threshold`
apart — i.e. there genuinely are no two close elements. -/
theorem has_close_elements_false_sound (numbers : List Rat) (threshold : Rat) :
    ⦃⌜True⌝⦄ has_close_elements numbers threshold ⦃⇓r =>
      ⌜r = false →
        PastaLean.pyAll ((PastaLean.pyRange (PastaLean.pyLen (PastaLean.pySort numbers) -ₚ (1 : Int))).map
          fun k => decide ((PastaLean.pySort numbers)⦋k +ₚ (1 : Int)⦌ -ₚ (PastaLean.pySort numbers)⦋k⦌ ≥ threshold)) = true⌝⦄ := by
  mvcgen [has_close_elements, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · Invariant.withEarlyReturn (onReturn := fun r _ => ⌜r = true⌝)
        (onContinue := fun cur _ => ⌜PastaLean.pyAll ((PastaLean.pyRange (cur.prefix.length : Int)).map
          fun k => decide ((PastaLean.pySort numbers)⦋k +ₚ (1 : Int)⦌ -ₚ (PastaLean.pySort numbers)⦋k⦌ ≥ threshold)) = true⌝)
  all_goals
    simp_all (config := { zetaDelta := true }) only [pyAll_pyRange_map, decide_eq_true_eq,
      PyHSub.hSub, PyHAdd.hAdd, ge_iff_le, gt_iff_lt, List.length_append, List.length_cons,
      List.length_nil, List.length_range, Int.ofNat_eq_natCast, Nat.cast_add, Nat.cast_one]
  all_goals
    first
      | exact Or.inr ⟨true, rfl, trivial, rfl⟩
      | grind [range_split]

theorem has_close_elements_false_correct (numbers : List Rat) (threshold : Rat) :
    (has_close_elements numbers threshold).run = false →
      PastaLean.pyAll ((PastaLean.pyRange (PastaLean.pyLen (PastaLean.pySort numbers) -ₚ (1 : Int))).map
        fun k => decide ((PastaLean.pySort numbers)⦋k +ₚ (1 : Int)⦌ -ₚ (PastaLean.pySort numbers)⦋k⦌ ≥ threshold)) = true :=
  has_close_elements_false_sound numbers threshold True.intro

end PastaBench.humaneval.HasCloseElements
