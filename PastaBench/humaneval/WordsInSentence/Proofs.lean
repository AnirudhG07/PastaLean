import PastaLean
import Libraries
import Std.Tactic.Do
open PastaLean Libraries Std.Do
set_option linter.all false
set_option mvcgen.warning false
set_option maxHeartbeats 1000000
namespace PastaBench.humaneval.WordsInSentence

def isPrime (a : Int) : Bool :=
  2 ≤ a && (List.range a.toNat).all (fun x => x < 2 || a % (x : Int) != 0)

/-- Keep the words whose length is prime, in order. -/
def words_in_sentence (s : String) : String :=
  String.intercalate " " ((s.splitOn " ").filter (fun w => isPrime (w.length)))

theorem words_in_sentence_correct :
    words_in_sentence "This is a test" = "is" ∧
    words_in_sentence "lets go for swimming" = "go for" ∧
    words_in_sentence "there is no place available here" = "there is no place" := by
  refine ⟨?_, ?_, ?_⟩ <;> native_decide

end PastaBench.humaneval.WordsInSentence
