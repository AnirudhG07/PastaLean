import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 200000

namespace PastaLean.User.Root

-- 2D/3D DP tables built with a comprehension (`[[..] for _ in range(n)]`) and updated in place
-- (`f[i][j] = v`). These are Array-backed (O(1) per update via pyModifyItem); correctness must match.
def grid_dp := fun (n : Int) ↦ fun (m : Int) ↦
  Id.run
    (do
      let mut f : List (List Int) :=
        (PastaLean.pyRange (n +ₚ (1 : Int))).map fun _ => PastaLean.pyListRepeat [(0 : Int)] (m +ₚ (1 : Int))
      f := PastaLean.pyModifyItem f (0 : Int) (fun __row_1 => PastaLean.pySetItem __row_1 (0 : Int) (1 : Int))
      for i in (PastaLean.pyRange (n +ₚ (1 : Int)))do
        for j in (PastaLean.pyRange (m +ₚ (1 : Int)))do
          if h_1 : i > (0 : Int) then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_2 => PastaLean.pySetItem __row_2 j (f⦋i⦌⦋j⦌ +ₚ f⦋i -ₚ (1 : Int)⦌⦋j⦌))
          else
            let _ := ()
          if h_2 : j > (0 : Int) then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_2 => PastaLean.pySetItem __row_2 j (f⦋i⦌⦋j⦌ +ₚ f⦋i⦌⦋j -ₚ (1 : Int)⦌))
          else
            let _ := ()
      let __py_ret_1 := f⦋n⦌⦋m⦌
      return __py_ret_1)

attribute [simp, taste_ingr] grid_dp

def grid_dp'rn := fun (n : Int) ↦ fun (m : Int) ↦
  Id.run
    (do
      let mut f : Array (Array Int) :=
        ((PastaLean.pyRange (n +ₚ (1 : Int))).map fun _ =>
            PastaLean.pyArrayRepeat #[(0 : Int)] (m +ₚ (1 : Int))) |>.toArray
      f := PastaLean.pyModifyItem f (0 : Int) (fun __row_1 => PastaLean.pySetItem __row_1 (0 : Int) (1 : Int))
      for i in (PastaLean.pyRange (n +ₚ (1 : Int)))do
        for j in (PastaLean.pyRange (m +ₚ (1 : Int)))do
          if h_1 : i > (0 : Int) then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_2 => PastaLean.pySetItem __row_2 j (f⦋i⦌⦋j⦌ +ₚ f⦋i -ₚ (1 : Int)⦌⦋j⦌))
          else
            let _ := ()
          if h_2 : j > (0 : Int) then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_2 => PastaLean.pySetItem __row_2 j (f⦋i⦌⦋j⦌ +ₚ f⦋i⦌⦋j -ₚ (1 : Int)⦌))
          else
            let _ := ()
      let __py_ret_1 := f⦋n⦌⦋m⦌
      return __py_ret_1)

def cube_fill := fun (n : Int) ↦
  Id.run
    (do
      let mut g : List (List (List Int)) :=
        (PastaLean.pyRange n).map fun _ => (PastaLean.pyRange n).map fun _ => PastaLean.pyListRepeat [(0 : Int)] n
      for i in (PastaLean.pyRange n)do
        for j in (PastaLean.pyRange n)do
          for k in (PastaLean.pyRange n)do
            g :=
              PastaLean.pyModifyItem g i
                (fun __row_1 =>
                  PastaLean.pyModifyItem __row_1 j
                    (fun __row_2 => PastaLean.pySetItem __row_2 k (i *ₚ (100 : Int) +ₚ j *ₚ (10 : Int) +ₚ k)))
      let mut total : Int := (0 : Int)
      for i in (PastaLean.pyRange n)do
        for j in (PastaLean.pyRange n)do
          for k in (PastaLean.pyRange n)do
            total := total +ₚ g⦋i⦌⦋j⦌⦋k⦌
      return total)

attribute [simp, taste_ingr] cube_fill

def cube_fill'rn := fun (n : Int) ↦
  Id.run
    (do
      let mut g : Array (Array (Array Int)) :=
        ((PastaLean.pyRange n).map fun _ =>
            ((PastaLean.pyRange n).map fun _ => PastaLean.pyArrayRepeat #[(0 : Int)] n) |>.toArray) |>.toArray
      for i in (PastaLean.pyRange n)do
        for j in (PastaLean.pyRange n)do
          for k in (PastaLean.pyRange n)do
            g :=
              PastaLean.pyModifyItem g i
                (fun __row_1 =>
                  PastaLean.pyModifyItem __row_1 j
                    (fun __row_2 => PastaLean.pySetItem __row_2 k (i *ₚ (100 : Int) +ₚ j *ₚ (10 : Int) +ₚ k)))
      let mut total : Int := (0 : Int)
      for i in (PastaLean.pyRange n)do
        for j in (PastaLean.pyRange n)do
          for k in (PastaLean.pyRange n)do
            total := total +ₚ g⦋i⦌⦋j⦌⦋k⦌
      return total)

def coin_change := fun (coins : List Int) ↦ fun (amount : Int) ↦
  Id.run
    (do
      let mut inf := PastaLean.pyNonFinite "inf"
      let __unpack_value_1 := (PastaLean.pyLen coins, amount)
      let __unpack_pair_1 := __unpack_value_1
      let mut m : Int := Prod.fst __unpack_pair_1
      let mut n : Int := Prod.snd __unpack_pair_1
      let mut f : List (List Int) :=
        (PastaLean.pyRange (m +ₚ (1 : Int))).map fun _ => PastaLean.pyListRepeat [inf] (n +ₚ (1 : Int))
      f := PastaLean.pyModifyItem f (0 : Int) (fun __row_1 => PastaLean.pySetItem __row_1 (0 : Int) (0 : Int))
      for _pair_1 in (PastaLean.pyIter (PastaLean.pyEnumerate coins (1 : Int)))do
        let i := Prod.fst _pair_1
        let x := Prod.snd _pair_1
        for j in (PastaLean.pyRange (n +ₚ (1 : Int)))do
          f := PastaLean.pyModifyItem f i (fun __row_2 => PastaLean.pySetItem __row_2 j f⦋i -ₚ (1 : Int)⦌⦋j⦌)
          if h_1 : j ≥ x then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_3 => PastaLean.pySetItem __row_3 j (PastaLean.pyMin [f⦋i⦌⦋j⦌, f⦋i⦌⦋j -ₚ x⦌ +ₚ (1 : Int)]))
          else
            let _ := ()
      let __py_ret_1 := if f⦋m⦌⦋n⦌ ≥ inf then -(1 : Int) else f⦋m⦌⦋n⦌
      return __py_ret_1)

attribute [simp, taste_ingr] coin_change

def coin_change'rn := fun (coins : List Int) ↦ fun (amount : Int) ↦
  Id.run
    (do
      let mut inf := PastaLean.pyNonFinite "inf"
      let __unpack_value_1 := (PastaLean.pyLen coins, amount)
      let __unpack_pair_1 := __unpack_value_1
      let mut m : Int := Prod.fst __unpack_pair_1
      let mut n : Int := Prod.snd __unpack_pair_1
      let mut f : Array (Array Int) :=
        ((PastaLean.pyRange (m +ₚ (1 : Int))).map fun _ => PastaLean.pyArrayRepeat #[inf] (n +ₚ (1 : Int))) |>.toArray
      f := PastaLean.pyModifyItem f (0 : Int) (fun __row_1 => PastaLean.pySetItem __row_1 (0 : Int) (0 : Int))
      for _pair_1 in (PastaLean.pyIter (PastaLean.pyEnumerate coins (1 : Int)))do
        let i := Prod.fst _pair_1
        let x := Prod.snd _pair_1
        for j in (PastaLean.pyRange (n +ₚ (1 : Int)))do
          f := PastaLean.pyModifyItem f i (fun __row_2 => PastaLean.pySetItem __row_2 j f⦋i -ₚ (1 : Int)⦌⦋j⦌)
          if h_1 : j ≥ x then 
            f :=
              PastaLean.pyModifyItem f i
                (fun __row_3 => PastaLean.pySetItem __row_3 j (PastaLean.pyMin [f⦋i⦌⦋j⦌, f⦋i⦌⦋j -ₚ x⦌ +ₚ (1 : Int)]))
          else
            let _ := ()
      let __py_ret_1 := if f⦋m⦌⦋n⦌ ≥ inf then -(1 : Int) else f⦋m⦌⦋n⦌
      return __py_ret_1)

def main' :=
  ((do
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (grid_dp (3 : Int) (3 : Int))]
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (cube_fill (3 : Int))]
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (coin_change [(1 : Int), (2 : Int), (5 : Int)] (11 : Int))]
      let _ ← PastaLean.ProofMode.pyPrintProof [pyPrintArg (coin_change [(2 : Int)] (3 : Int))]) :
    PastaLean.ProofMode.PyProofM _)

attribute [simp] main'

def main''rn :=
  ((do
      let _ ← pyPrintIO [pyPrintArg (grid_dp'rn (3 : Int) (3 : Int))]
      let _ ← pyPrintIO [pyPrintArg (cube_fill'rn (3 : Int))]
      let _ ← pyPrintIO [pyPrintArg (coin_change'rn [(1 : Int), (2 : Int), (5 : Int)] (11 : Int))]
      let _ ← pyPrintIO [pyPrintArg (coin_change'rn [(2 : Int)] (3 : Int))]) :
    IO _)

def main : IO Unit := do
  let _ := main'
  pure ()

def main'rn : IO Unit := do
  let _ := main''rn
  pure ()

end PastaLean.User.Root
