import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.Encode

/-- Swap the case of a letter, then shift a resulting vowel two letters ahead. -/
def encodeCh (c : Char) : Char :=
  let s : Char :=
    if c.isUpper then Char.ofNat (c.toNat + 32)
    else if c.isLower then Char.ofNat (c.toNat - 32)
    else c
  if s ∈ ['a','e','i','o','u','A','E','I','O','U'] then Char.ofNat (s.toNat + 2) else s

def encode (message : String) : String := String.mk (message.data.map encodeCh)

theorem encode_correct :
    encode "TEST" = "tgst" ∧
    encode "Mudasir" = "mWDCSKR" ∧
    encode "YES" = "ygs" ∧
    encode "This is a message" = "tHKS KS C MGSSCGG" := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.Encode
