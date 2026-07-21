import PastaLean
import Libraries
import Std.Tactic.Do

open PastaLean
open Libraries
open Std.Do

set_option linter.all false
set_option mvcgen.warning false

set_option maxHeartbeats 0

-- Edge case: a class-free program under --heap. No classes means no value universe is needed, so
-- the prelude is skipped and output should match the default path (a no-op for --heap at this stage).
def x :=
  (5 : Int)

def y :=
  x +ₚ (3 : Int)

def z :=
  y *ₚ (2 : Int)
