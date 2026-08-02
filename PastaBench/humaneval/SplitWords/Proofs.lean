import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.SplitWords

/-- Split on whitespace; else on commas; else count lowercase letters at an odd alphabet index. -/
def split_words (txt : String) : (List String) ⊕ Nat :=
  if txt.data.any (fun c => c == ' ' || c == '\n' || c == '\r' || c == '\t') then
    Sum.inl ((txt.splitOn " ").filter (fun w => w != ""))
  else if txt.data.any (· == ',') then Sum.inl (txt.splitOn ",")
  else Sum.inr ((txt.data.filter (fun c => c.isLower && (c.toNat - 'a'.toNat) % 2 == 1)).length)

theorem split_words_correct :
    split_words "Hello world!" = Sum.inl ["Hello", "world!"] ∧
    split_words "Hello,world!" = Sum.inl ["Hello", "world!"] ∧
    split_words "Hello world,!" = Sum.inl ["Hello", "world,!"] ∧
    split_words "Hello,Hello,world !" = Sum.inl ["Hello,Hello,world", "!"] ∧
    split_words "abcdef" = Sum.inr 3 := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.SplitWords
