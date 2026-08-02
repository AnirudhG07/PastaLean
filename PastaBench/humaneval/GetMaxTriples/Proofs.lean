import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.GetMaxTriples

/-- a[i] = i*i - i + 1 (i from 1..n); count triples i<j<k with a[i]+a[j]+a[k] ≡ 0 (mod 3). -/
def get_max_triples (n : Nat) : Int := Id.run do
  let a : List Int := (List.range n).map (fun i => let i : Int := (i : Int) + 1; i * i - i + 1)
  let mut c : Int := 0
  for i in [0:a.length] do
    for j in [i+1:a.length] do
      for k in [j+1:a.length] do
        if (a[i]! + a[j]! + a[k]!) % 3 == 0 then c := c + 1
  return c

theorem get_max_triples_correct :
    get_max_triples 5 = 1 ∧ get_max_triples 6 = 4 ∧
    get_max_triples 10 = 36 ∧ get_max_triples 1 = 0 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.GetMaxTriples
