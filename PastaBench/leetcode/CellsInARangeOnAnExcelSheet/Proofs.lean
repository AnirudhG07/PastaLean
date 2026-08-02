import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.leetcode.CellsInARangeOnAnExcelSheet

def cellsInRange := fun (s : String) ↦
  (PastaLean.pyRange (PastaLean.pyOrd s⦋(-2 : Int)⦌ +ₚ (1 : Int)) (PastaLean.pyOrd s⦋(0 : Int)⦌)).flatMap fun i =>
    (PastaLean.pyRange (PastaLean.pyInt s⦋(-1 : Int)⦌ +ₚ (1 : Int)) (PastaLean.pyInt s⦋(1 : Int)⦌)).map fun j =>
      PastaLean.pyChr i +ₚ PastaLean.pyStr j

attribute [simp] cellsInRange

theorem pyLen_list {α : Type} (l : List α) : PastaLean.pyLen l = (l.length : Int) := rfl

theorem pyRange_length_one (stop start : Int) :
    (PastaLean.pyRange stop start 1).length = (stop - start).toNat := by
  unfold PastaLean.pyRange
  norm_num [List.length_map, List.length_range']

theorem length_flatMap_const {α β : Type} (f : α → List β) (k : Nat)
    (h : ∀ x, (f x).length = k) : ∀ (l : List α), (l.flatMap f).length = l.length * k
  | [] => by simp
  | x :: xs => by
    rw [List.flatMap_cons, List.length_append, h x, length_flatMap_const f k h xs,
        List.length_cons]
    ring

@[taste_ingr]
theorem cellsInRange_correct :
    ∀ (s : String),
      PastaLean.pyLen s = (5 : Int) →
        s⦋(2 : Int)⦌ = ":" →
          PastaLean.pyOrd "A" ≤ PastaLean.pyOrd s⦋(0 : Int)⦌ ∧ PastaLean.pyOrd s⦋(0 : Int)⦌ ≤ PastaLean.pyOrd "Z" →
            PastaLean.pyOrd "A" ≤ PastaLean.pyOrd s⦋(-2 : Int)⦌ ∧ PastaLean.pyOrd s⦋(-2 : Int)⦌ ≤ PastaLean.pyOrd "Z" →
              PastaLean.pyOrd "1" ≤ PastaLean.pyOrd s⦋(1 : Int)⦌ ∧ PastaLean.pyOrd s⦋(1 : Int)⦌ ≤ PastaLean.pyOrd "9" →
                PastaLean.pyOrd "1" ≤ PastaLean.pyOrd s⦋(-1 : Int)⦌ ∧
                    PastaLean.pyOrd s⦋(-1 : Int)⦌ ≤ PastaLean.pyOrd "9" →
                  PastaLean.pyOrd s⦋(0 : Int)⦌ ≤ PastaLean.pyOrd s⦋(-2 : Int)⦌ →
                    PastaLean.pyInt s⦋(1 : Int)⦌ ≤ PastaLean.pyInt s⦋(-1 : Int)⦌ →
                      PastaLean.pyLen (cellsInRange s) =
                        (PastaLean.pyOrd s⦋(-2 : Int)⦌ -ₚ PastaLean.pyOrd s⦋(0 : Int)⦌ +ₚ (1 : Int)) *ₚ
                          (PastaLean.pyInt s⦋(-1 : Int)⦌ -ₚ PastaLean.pyInt s⦋(1 : Int)⦌ +ₚ (1 : Int)) := by
  intro s h5 hcol hA hB2 h1c h2c hord hint
  simp only [cellsInRange, pyLen_list]
  rw [length_flatMap_const _
        (PastaLean.pyRange (PastaLean.pyInt s⦋(-1 : Int)⦌ +ₚ (1 : Int)) (PastaLean.pyInt s⦋(1 : Int)⦌)).length
        (fun i => by rw [List.length_map])]
  rw [pyRange_length_one, pyRange_length_one]
  simp only [PyHAdd.hAdd, PyHSub.hSub, PyHMul.hMul]
  have hA' : ((PastaLean.pyOrd s⦋(-2 : Int)⦌ + 1 - PastaLean.pyOrd s⦋(0 : Int)⦌).toNat : Int)
      = PastaLean.pyOrd s⦋(-2 : Int)⦌ + 1 - PastaLean.pyOrd s⦋(0 : Int)⦌ := by omega
  have hB' : ((PastaLean.pyInt s⦋(-1 : Int)⦌ + 1 - PastaLean.pyInt s⦋(1 : Int)⦌).toNat : Int)
      = PastaLean.pyInt s⦋(-1 : Int)⦌ + 1 - PastaLean.pyInt s⦋(1 : Int)⦌ := by omega
  rw [Nat.cast_mul, hA', hB']
  ring

end PastaBench.leetcode.CellsInARangeOnAnExcelSheet
