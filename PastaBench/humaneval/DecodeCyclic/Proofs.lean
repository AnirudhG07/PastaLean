import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.DecodeCyclic

/-- Inverse of encode_cyclic: for each 3-char group `abc`, map it back to `cab`. -/
def decodeGroup (g : String) : String :=
  if g.length == 3 then String.mk [g.data[2]!] ++ String.mk (g.data.take 2) else g

def decode_cyclic (s : String) : String := Id.run do
  let n := s.length
  let mut groups : List String := []
  for i in [0:(n + 2) / 3] do
    let lo := 3 * i
    let hi := min (3 * i + 3) n
    groups := groups ++ [String.mk ((s.data.drop lo).take (hi - lo))]
  return String.join (groups.map decodeGroup)

theorem decode_cyclic_correct :
    decode_cyclic "uzfplzjfzcltmdly" = "fuzzplzjftcllmdy" ∧
    decode_cyclic "nzyegaghrzqwrdzxckn" = "ynzaegrghwzqzrdkxcn" := by
  refine ⟨?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.DecodeCyclic
