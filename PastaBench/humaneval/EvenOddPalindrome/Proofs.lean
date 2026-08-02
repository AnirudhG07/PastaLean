import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.EvenOddPalindrome

def even_odd_palindrome := fun n ↦
  (do
    let __unpack_value_1 := ((0 : Int), (0 : Int))
    let __unpack_pair_1 := __unpack_value_1
    let mut odd_cnt : Int := Prod.fst __unpack_pair_1
    let mut even_cnt : Int := Prod.snd __unpack_pair_1
    for i in (PastaLean.pyRange (n +ₚ (1 : Int)) (1 : Int))do
      let _ := Libraries.passta.pyPassInvariant (decide (odd_cnt +ₚ even_cnt ≤ i -ₚ (1 : Int)))
      if h_1 : PastaLean.pyStr i = PastaLean.pySlice (PastaLean.pyStr i) none none (some (-(1 : Int))) then
        if h_2 : i %ₚ (2 : Int) = (1 : Int) then
          odd_cnt := odd_cnt +ₚ (1 : Int)
        else
          even_cnt := even_cnt +ₚ (1 : Int)
      else
        let _ := ()
    let __py_ret_1 := (even_cnt, odd_cnt)
    return __py_ret_1 : Id _)

-- Deep counting law: the even and odd palindrome counts together never exceed n (each of the n
-- integers 1..n contributes at most one). Invariant: the running sum ≤ number of iterations done.
@[spec]
theorem even_odd_palindrome_spec :
    ⦃⌜n ≥ (1 : Int)⌝⦄ even_odd_palindrome n ⦃⇓result => ⌜result⦋(0 : Int)⦌ +ₚ result⦋(1 : Int)⦌ ≤ n⌝⦄ := by
  mvcgen [even_odd_palindrome, PastaLean.pyRange_forIn, PastaLean.pyRange_forIn_start] invariants
    · ⇓⟨cur, odd_cnt, even_cnt⟩ => ⌜odd_cnt + even_cnt ≤ (cur.prefix.length : Int)⌝
  all_goals (try simp_all (config := { zetaDelta := true }) [taste_ingr])
  all_goals (first | omega | grind [pyLen_list_nonneg, Int.toNat_of_nonneg])

theorem even_odd_palindrome_correct :
    ∀ n, n ≥ (1 : Int) → let result := (even_odd_palindrome n).run;
      result⦋(0 : Int)⦌ +ₚ result⦋(1 : Int)⦌ ≤ n := by
  intro n hpre
  exact even_odd_palindrome_spec hpre

end PastaBench.humaneval.EvenOddPalindrome
