import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.DecodeShift

/-- Inverse of a Caesar shift-by-5 over lowercase letters. -/
def decode_shift (s : String) : String :=
  String.mk (s.data.map (fun ch => Char.ofNat ((ch.toNat - 'a'.toNat + 21) % 26 + 'a'.toNat)))

theorem decode_shift_correct :
    decode_shift "tantywccpjkimslotpzs" = "oviotrxxkefdhngjokun" ∧
    decode_shift "clknfxdnox" = "xgfiasyijs" ∧
    decode_shift "brhkdngfwd" = "wmcfyibary" := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.DecodeShift
