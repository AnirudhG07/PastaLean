import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 800000

namespace PastaBench.humaneval.RollingMax

def rollingMaxAux (cur : Int) : List Int → List Int
  | [] => []
  | x :: xs => let m := max cur x; m :: rollingMaxAux m xs

def rolling_max : List Int → List Int
  | [] => []
  | x :: xs => x :: rollingMaxAux x xs

theorem rollingMaxAux_length (cur : Int) (l : List Int) :
    (rollingMaxAux cur l).length = l.length := by
  induction l generalizing cur with
  | nil => rfl
  | cons x xs ih => simp [rollingMaxAux, ih]

theorem rolling_max_length (l : List Int) :
    (rolling_max l).length = l.length := by
  cases l with
  | nil => rfl
  | cons x xs => simp [rolling_max, rollingMaxAux_length]

end PastaBench.humaneval.RollingMax
