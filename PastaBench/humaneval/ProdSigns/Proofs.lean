import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.ProdSigns

def signOf (x : Int) : Int := if x > 0 then 1 else if x < 0 then -1 else 0

def sumAbs (l : List Int) : Int := l.foldl (fun s x => s + x.natAbs) 0

def signProd (l : List Int) : Int := l.foldl (fun s x => s * signOf x) 1

def prod_signs (l : List Int) : Option Int :=
  if l = [] then none
  else if (0 : Int) ∈ l then some 0
  else some (sumAbs l * signProd l)

theorem prod_signs_correct (l : List Int) :
    prod_signs [] = none ∧
    (l ≠ [] → (0 : Int) ∈ l → prod_signs l = some 0) ∧
    (l ≠ [] → (0 : Int) ∉ l → prod_signs l = some (sumAbs l * signProd l)) := by
  refine ⟨rfl, ?_, ?_⟩ <;> intro h1 h2 <;> simp [prod_signs, h1, h2]

end PastaBench.humaneval.ProdSigns
