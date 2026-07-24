import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

def factorial := fun (n : Int) ↦
  (pure
      (let __py_sf :=
        PastaLean.pyWhile
          (fun s =>
            let result := (s).1;
            let i := (s).2;
            (n +ₚ (1 : Int) -ₚ i : Int).toNat)
          (fun s =>
            let result := (s).1;
            let i := (s).2;
            i ≤ n)
          (fun s =>
            let result := (s).1;
            let i := (s).2;
            let result := result *ₚ i;
            let i := i +ₚ (1 : Int);
            (result, i))
          ((1 : Int), (1 : Int));
      let result := (__py_sf).1;
      let i := (__py_sf).2;
      result) :
    Id _)

@[spec]
theorem factorial_spec : ⦃⌜n ≥ (0 : Int)⌝⦄ factorial n ⦃⇓__py_r => ⌜__py_r ≥ (1 : Int)⌝⦄ :=
  by
  mvcgen [factorial]
  ·
    exact
      PastaLean.pyWhile_correct (I := fun s =>
        let result := (s).1;
        let i := (s).2;
        ((1 : Int) ≤ i ∧ i ≤ n +ₚ (1 : Int)) ∧ result ≥ (1 : Int))
        (Q := fun s =>
        let result := (s).1;
        let i := (s).2;
        result ≥ (1 : Int))
        (fun s =>
          let result := (s).1;
          let i := (s).2;
          (n +ₚ (1 : Int) -ₚ i : Int).toNat)
        (fun s =>
          let result := (s).1;
          let i := (s).2;
          i ≤ n)
        (fun s =>
          let result := (s).1;
          let i := (s).2;
          let result := result *ₚ i;
          let i := i +ₚ (1 : Int);
          (result, i))
        ((1 : Int), (1 : Int))
        (by
          intros <;> (try simp_all (config := { zetaDelta := true })) <;> (try and_intros) <;>
            first
            | omega
            | nlinarith
            | positivity
            | grind
            | sorry)
        (by
          intros <;> (try simp_all (config := { zetaDelta := true })) <;> (try and_intros) <;>
            first
            | omega
            | nlinarith
            | positivity
            | grind
            | sorry)
        (by
          intros <;> (try simp_all (config := { zetaDelta := true })) <;> (try and_intros) <;>
            first
            | omega
            | nlinarith
            | positivity
            | grind
            | sorry)

def factorial'rn := fun (n : Int) ↦
  Id.run
    (do
      let _ := Libraries.passta.pyPassRequires (decide (n ≥ (0 : Int)))
      let mut result : Int := (1 : Int)
      let mut i : Int := (1 : Int)
      while (i ≤ n) do
        let _ := Libraries.passta.pyPassInvariant (decide ((1 : Int) ≤ i))
        let _ := Libraries.passta.pyPassInvariant (decide (i ≤ n +ₚ (1 : Int)))
        let _ := Libraries.passta.pyPassInvariant (decide (result ≥ (1 : Int)))
        let _ := Libraries.passta.pyPassDecreases (n +ₚ (1 : Int) -ₚ i)
        result := result *ₚ i
        i := i +ₚ (1 : Int)
      return result)