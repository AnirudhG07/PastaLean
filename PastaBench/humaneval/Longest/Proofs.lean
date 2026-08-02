import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.Longest

def longest : List String → Option String := fun (strings : List String) ↦
  Id.run
    (do
      if h_1 : ¬PastaLean.pyTruthy strings = true then
        return Option.none
      else
        let _ := ()
      let mut maxlen : Int := PastaLean.pyMax ((PastaLean.pyIter strings).map fun x => PastaLean.pyLen x)
      for s in (PastaLean.pyIter strings)do
        if h_2 : PastaLean.pyLen s = maxlen then
          return s
        else
          let _ := ()
      return default)

-- Returns the first longest string, or none for the empty list.
theorem longest_correct :
    longest [] = none
      ∧ longest ["x", "y", "z"] = some "x"
      ∧ longest ["x", "yyy", "zzzz", "www", "kkkk", "abc"] = some "zzzz"
      ∧ longest ["", "a", "aa", "aaa"] = some "aaa"
      ∧ longest ["a", "b", "aa", "bb"] = some "aa" := by
  native_decide

end PastaBench.humaneval.Longest
